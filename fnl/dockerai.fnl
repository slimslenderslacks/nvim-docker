(module dockerai
  {autoload {nvim aniseed.nvim
             core aniseed.core
             string aniseed.string
             util slim.nvim
             lsps lsps
             notebook notebook}})

(vim.lsp.set_log_level "TRACE")
(def use-nix? true)

(defn jwt []
  (let [p (vim.system 
            ["docker-credential-desktop" "get"] 
            {:text true :stdin "https://index.docker.io/v1//access-token"})
        obj (p:wait)]
    (. (vim.json.decode (. obj :stdout)) :Secret)))

(defn decode-payload [s]
  (vim.json.decode
    (vim.base64.decode (.. (. (vim.split s "." {:plain true}) 2) "="))))

(comment
  (decode-payload (jwt)))

;err - error info dict or nil
;result - result key of the lsp response
;ctx - table of calling states
;config - handler defined config table
(defn prompt-handler [cb]
  {:fnl/docstring 
   "returns a handler that recognizes complete, function_calls, and content response payloads
            forwards response on to content callback which will map extension-id to a registration"
   :fnl/arglist [question-id callback prompt]}
  (fn [err result ctx config]
    (if err
      ((. cb :error) (core.get err "extension/id") err)
      (let [content (. result :content)]
        (if (or 
                (core.get content :complete)
                (core.get content :function_call)
                (core.get content :content))
          ;(vim.json.decode (core.get fc :arguments))
          ;; TODO check whether the arguments have to be parsed
          ;;      for the create-notebook function calls
          ((. cb :content) 
           (core.get result "extension/id") 
           content)
          (core.get result "extension/id")
          true
          ((. cb :error) 
           (core.get result "extension/id") 
           (core.str "content not recognized: " result)))))))

(defn exit-handler [cb]
  "returns a handler for lsp $/exit callbacks"
  (fn [err result ctx config]
    (if err
      ;; will never happen
      ((. cb :error) (core.get err "extension/id") err)
      ;; will have extension/id and exit
      ((. cb :exit) (core.get result "extension/id") result))))

(defn jwt-handler [err result ctx config]
  "handler for lsps that need a jwt"
  (if err
    (core.println "jwt err: " err))
  (jwt))

(defn start-lsps [prompt-handler exit-handler]
  "start both docker_ai and docker_lsp services"
  (let [root-dir ;; TODO (util.git-root)
          (vim.fn.getcwd)
        extra-handlers {"docker/jwt" jwt-handler}]
    (vim.lsp.start {:name "docker_ai"
                    :cmd ["docker" "run"
                          "--rm" "--init" "--interactive"
                          "docker/labs-assistant-ml:staging"]
                    :root_dir root-dir
                    :handlers (core.merge 
                                {"$/prompt" prompt-handler
                                 "$/exit" exit-handler}
                                extra-handlers)})
    (lsps.start root-dir extra-handlers)))

(defn stop []
  (let [docker-lsp (. (lsps.get-client-by-name "docker_lsp") :id)
        docker-ai (. (lsps.get-client-by-name "docker_ai") :id)]
    (when docker-lsp (vim.lsp.stop_client docker-lsp  false))
    (when docker-ai (vim.lsp.stop_client docker-ai false))))

(var registrations {})

(defn run-prompt [question-id callback prompt]
  "call the docker_lsp lsp to get project context, and then call
     the docker_ai lsp with the context and the prompt
     The callback must understand the $/prompt notification"
  {:fnl/docstring "call Docker AI and register callback for this question identifier"
   :fnl/arglist [question-id callback prompt]}
  (set registrations (core.assoc registrations question-id callback))
  (let [docker-ai-lsp (lsps.get-client-by-name "docker_ai")
        docker-lsp (lsps.get-client-by-name "docker_lsp")]
    (let [result (docker-ai-lsp.request_sync 
                   "prompt" 
                   (core.merge 
                     (. (docker-lsp.request_sync "docker/project-facts" {"vs-machine-id" ""} 60000) :result) 
                     {"extension/id" question-id
                      "question" {"prompt" prompt}}
                     {:dockerImagesResult []
                      :dockerPSResult []
                      :dockerDFResult []
                      :dockerCredential (let [k (jwt)] 
                                          {:jwt k
                                           :parsedJWT (decode-payload k)})
                      :platform {:arch "arm64"
                                 :platform "darwin"
                                 :release "23.0.0"}
                      :vsMachineId ""
                      :isProduction true
                      :notebookOpens 1
                      :notebookCloses 1
                      :notebookUUID ""
                      :dataTrackTimestamp 0
                      :stream true}))] 
      (core.println result))))

(defn questions []
  (let [docker-ai-lsp (lsps.get-client-by-name "docker_ai")
        docker-lsp (lsps.get-client-by-name "docker_lsp")]
    (let [result (. (docker-lsp.request_sync "docker/project-facts" {"vs-machine-id" ""} 60000) :result)]
      (core.concat
        (. result :project/potential-questions)
        ["Summarize this project" 
         "Can you write a Dockerfile for this project"
         "How do I build this Docker project?"
         "Custom Question"]))))

;; this is where we define the question specific content, error and exit handlers
;; content handler has to handle function_calls and content nodes
(defn into-buffer [prompt]
  "stream content into a buffer"
  (let [lines (string.split prompt "\n")
        [win buf] (util.open lines)
        t (util.show-spinner buf (core.inc (core.count lines)))]
    (nvim.buf_set_lines buf -1 -1 false ["" ""])
    ;; run Docker AI
    (run-prompt 
      (util.uuid) 
      {:content 
       (fn [extension-id message] 
         (t:stop) 
         (when (vim.api.nvim_win_is_valid win)
           (vim.api.nvim_win_close win true))
         (notebook.docker-ai-content-handler extension-id message))
       :error (fn [_ message] (core.println (core.str "error: " message)))
       :exit (fn [id message] (core.println (core.str "finished prompt " prompt) id))}        
      prompt)))

(defn start []
  (let [cb {:exit (fn [id message]
                    ((. (. registrations id) :exit) id message)
                    ;; TODO remove the handler
                    )
            :error (fn [id message]
                     (core.println id message))
            :content (fn [id message]
                       ((. (. registrations id) :content) id message))}]
    (start-lsps
      (prompt-handler cb)
      (exit-handler cb))))

(defn update-buf [buf lines]
  (vim.api.nvim_buf_call
    buf
    (fn [] 
      (vim.cmd "norm! G")
      (vim.api.nvim_put lines "" true true))))

(defn callback [buf]
  "test callback that just writes everthing into a buffer"
  {:exit (fn [id message] (update-buf buf [id (vim.json.encode message) "----" ""]))
   :error (fn [id message] (update-buf buf [id (vim.json.encode message) "----" ""]))
   :content (fn [id message] (update-buf buf [id (vim.json.encode message) "----" ""]))})



(comment
  (def buf (vim.api.nvim_create_buf true true))
  
  (start) 
  (lsps.list)
  (stop)

  (run-prompt "18" (callback buf) "Can you write a Dockerfile for this project?")
  (run-prompt "19" (callback buf) "Summarize this project")
  (run-prompt "21" (callback buf) "How do I dockerize my project")
  (run-prompt "22" (callback buf) "How do I build this Docker project?")
  )

(defn lsp-debug [_]
  (vim.ui.select
      ["documents"
       "project-context"
       "tracking-data"
       "login"
       "alpine-packages"
       "repositories"
       "client-settings"] 
      {:prompt "Select a prompt:"
       :format (fn [item] (item:gsub "_" " "))}
      (fn [selected _]
        (let [client (lsps.get-client-by-name "docker_lsp")]
          (client.request_sync "docker/debug" {:type selected})))))

(vim.api.nvim_create_user_command "DockerAIStart" start {:desc "Start the LSPs for Docker AI"})
(vim.api.nvim_create_user_command "DockerAIStop" stop {:desc "Stop the LSPs for Docker AI"})
(vim.api.nvim_create_user_command "DockerAIDebug" lsp-debug {:desc "Get some state from the Docker LSP"})

(defn tail_server_info []
  (let [clients (vim.lsp.get_active_clients)]
    (each [n client (pairs clients)]
      (if (= client.name "docker_lsp")
        (let [result (client.request_sync "docker/serverInfo/raw" {} 5000)]
          (print result.result.port result.result.log-path result.result.team-id)
          (nvim.command  (core.str "vs | :term bash -c \"tail -f " result.result.log-path "\"")))))))

(defn set_team_id [args]
  (let [clients (vim.lsp.get_active_clients)]
    (each [n client (pairs clients)]
      (if (= client.name "docker_lsp")
        (let [result (client.request_sync "docker/team-id" args 5000)]
          (print result))))))

(defn docker_server_info [args]
  (let [clients (vim.lsp.get_active_clients)]
    (each [n client (pairs clients)]
      (if (= client.name "docker_lsp")
        (let [result (client.request_sync "docker/serverInfo/show" args 5000)]
          (core.println result))))))

(defn docker_login [args]
  (let [clients (vim.lsp.get_active_clients)]
    (each [n client (pairs clients)]
      (if (= client.name "docker_lsp")
        (let [result (client.request_sync "docker/login" args 5000)]
          (print result))))))

(defn docker_logout [args]
  (let [clients (vim.lsp.get_active_clients)]
    (each [n client (pairs clients)]
      (if (= client.name "docker_lsp")
        (let [result (client.request_sync "docker/logout" args 5000)]
          (print result))))))

(nvim.create_user_command "DockerWorkspace" set_team_id {:nargs "?"})
(nvim.create_user_command "DockerServerInfo" docker_server_info {:nargs "?"})
(nvim.create_user_command "DockerLogin" docker_login {:nargs "?"})
(nvim.create_user_command "DockerLogout" docker_logout {:nargs "?"})
(nvim.create_user_command "DockerTailServerInfo" tail_server_info {:nargs "?"})

