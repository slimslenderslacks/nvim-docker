(module dockerai
  {autoload {nvim aniseed.nvim
             core aniseed.core
             string aniseed.string
             util slim.nvim
             lsps lsps}})

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
        (when (or 
                (core.get content :complete)
                (core.get content :function_call)
                (core.get content :content))
          ((. cb :content) 
           (core.get result "extension/id") 
           (if (core.get content :function_call)
             (core.update 
               content :function_call 
               (fn [fc] (core.assoc fc :arguments (vim.json.decode (core.get fc :arguments)))))
             content)))))))

(defn exit-handler [cb]
  "returns a handler for question exits"
  (fn [err result ctx config]
    (if err
      ;; will never happen
      ((. cb :error) (core.get err "extension/id") err)
      ;; will have extension/id and exit
      ((. cb :exit) (core.get result "extension/id") result))))

(defn jwt-handler 
  [err result ctx config]
  (if err
    (core.println "jwt err: " err))
  (jwt))

(defn start-lsps [prompt-handler exit-handler]
  ;; this lsp calls commands but it is never attached to buffers
  (let [root-dir (util.git-root)
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

(defn update-buf [buf lines]
  (vim.api.nvim_buf_call
    buf
    (fn [] 
      (vim.cmd "norm! G")
      (vim.api.nvim_put lines "" true true))))

(defn complain [{:path path 
                 :languageId language-id 
                 :startLine start-line 
                 :endLine end-line 
                 :edit edit 
                 :reason reason}]
  (let [docker-lsp (lsps.get-client-by-name "docker_lsp")
        params {:uri {:external (.. "file://" path)} 
                :message reason 
                :range 
                {:start 
                 {:line (core.dec start-line)
                  :character 0} 
                 :end 
                 {:line (if end-line (- end-line 1) (- start-line 1))
                  :character -1}} 
                :edit edit}]
    (docker-lsp.request_sync "docker/complain" params 10000)))

(defn append [current-lines s]
  (core.str (string.join "\n" current-lines) s))

(defn docker-ai-content-handler [current-lines message]
  "returns an array of strings"
  (if 
    ;; content
    (. message :content)
    (string.split (append current-lines (. message :content)) "\n")

    ;; cell-execution or suggest-command
    (and 
      (. message :function_call) 
      (or
        (= (-> message (. :function_call) (. :name)) "cell-execution")
        (= (-> message (. :function_call) (. :name)) "suggest-command")))
    (core.concat 
      current-lines
      ["" "```bash"] 
      (string.split (-> message (. :function_call) (. :arguments) (. :command)) "\n") 
      ["```" ""])  

    ;; update-file
    (and 
      (. message :function_call) 
      (= (-> message (. :function_call) (. :name)) "update-file"))
    (let [{:path path} 
          (-> message (. :function_call) (. :arguments))]
      (util.open-file path)
      (complain (-> message (. :function_call) (. :arguments)))  
       
      (core.concat
        current-lines
        ["" "I've opened a buffer to the right and created a code action for your review."]))  

    ;; create-notebook
    (and 
      (. message :function_call) 
      (= (-> message (. :function_call) (. :name)) "create-notebook"))
    (let [{:notebook notebook :cells cells} (-> message (. :function_call) (. :arguments))
          notebook-content (core.mapcat
                             (fn [{:kind kind :value value :languageId language-id}]
                               (core.concat
                                 [(.. "```" language-id)]
                                 (string.split value "\n")
                                 ["```" ""]))
                           (. cells :cells))]
      (let [buf (util.open-file notebook)]
        (util.append buf notebook-content)
        (core.concat
          current-lines
          ["" "I've opened a new notebook to the right."]))) 

    ;; show-notification
    (and 
      (. message :function_call) 
      (= (-> message (. :function_call) (. :name)) "show-notification"))
    (let [{:level level :message message :actions actions}
          (-> message (. :function_call) (. :arguments))]
      ;; neovim supports TRACE DEBUG INFO WARN ERROR OFF
      ;; DEBUG INFO WARNING ERROR
      (vim.api.nvim_notify message vim.log.levels.INFO {})
      (core.concat
        current-lines
        [""]))  

    ;; complete
    (. message :complete)
    (core.concat
      current-lines
      [""]) 

    ;; default - show json payload
    (core.concat
      current-lines
      ["" "```json" (vim.json.encode message) "```" ""])))

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
       (fn [_ message] 
         (t:stop) 
         (let [current-lines (vim.api.nvim_buf_get_lines buf 4 -1 false)
               lines (docker-ai-content-handler current-lines message)]
           (vim.api.nvim_buf_set_lines buf 4 -1 false lines)))
       :error (fn [_ message] (core.println message))
       :exit (fn [id message] (core.println "finished" id))}        
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

(defn callback [buf]
  {:exit (fn [id message] (update-buf buf [id (vim.json.encode message) "----" ""]))
   :error (fn [id message] (update-buf buf [id (vim.json.encode message) "----" ""]))
   :content (fn [id message] (update-buf buf [id (vim.json.encode message) "----" ""]))})

(defn bottom-terminal [cmd]
  (let [current-win (nvim.tabpage_get_win 0)
        original-buf (nvim.win_get_buf current-win)
        term-buf (nvim.create_buf false true)]
    (vim.cmd "split")
    (let [new-win (nvim.tabpage_get_win 0)]
      (nvim.win_set_buf new-win term-buf)
      (nvim.fn.termopen cmd))))

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



