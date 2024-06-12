(module runbooks
  {autoload {core aniseed.core
             nvim aniseed.nvim
             curl plenary.curl
             fs aniseed.fs
             string aniseed.string
             util slim.nvim}})

(defn opena-api-key []
  (or (case (core.slurp (vim.fn.printf "%s/.open-api-key" (os.getenv "HOME")))
        s (string.trim s))
      (os.getenv "OPENAI_API_KEY")
      (error "unable to lookup OPENAI_API_KEY or read from $HOME/.open-api-key")))

(defn docker-run [args]
  (case-try (pcall (fn [] (vim.system 
                             args
                             {:text true})))
    (true obj) (obj.wait obj)
    v (case v
        {:code 0 :stdout out} (vim.json.decode out)
        {:code code} (error (vim.fn.printf "docker exited with code %d" code))
        {:signal signal} (error (vim.fn.printf "docker process was killed by signal %d" signal)))
    (catch
      (false e) (error "docker could not be executed"))))

(defn prompt-types []
  (core.reduce 
    (fn [agg {:title title :type type}] (core.assoc agg title type)) 
    {}
    (docker-run ["docker" 
                 "run"
                 "--rm"
                 "-v" "/var/run/docker.sock:/var/run/docker.sock"
                 "vonwig/prompts:latest"
                 "prompts"])))

(comment
  (prompt-types))

(defn prompts [type]
  (docker-run
    ["docker" 
     "run"
     "--rm"
     "-v" "/var/run/docker.sock:/var/run/docker.sock"
     "--mount" "type=volume,source=docker-prompts,target=/prompts"
     "vonwig/prompts:latest"
     (vim.fn.getcwd)
     "jimclark106"
     "darwin"
     type]))

(comment
  (prompts "docker"))

;; TODO deal with failed POSTS
(defn openai [messages cb]
  (curl.post 
    "https://api.openai.com/v1/chat/completions"
    {:body (vim.json.encode {:model "gpt-4"
                             :messages messages
                             :stream true})
     :headers {:Authorization (core.str "Bearer " (opena-api-key))
               :Content-Type "application/json"}
     :stream (fn [_ chunk _]
               ;; these are sse events
               (cb
                 (case-try 
                   chunk
                   s (if (vim.startswith s "data:") (s:sub 7))
                   s (pcall (fn [] (vim.json.decode s)))
                   (true obj) (->
                                 obj
                                 (. :choices)
                                 (core.first)
                                 (. :delta)
                                 (. :content)
                                 )
                   (catch 
                     s s))))}))

(comment
  (util.stream-into-empty-buffer openai (prompts "docker"))
  (openai (prompts "docker") (fn [s] (core.println s))))

(defn generate-runbook []
  (let [m (core.assoc (prompt-types) "custom" "custom")]
    (vim.ui.select
      (core.keys m)
      {:prompt "Select prompt type"}
      (fn [selected _]
        (let [prompt-type (if (= selected "custom")
                            (vim.fn.input "prompt github ref: ")
                            (core.get m selected))]
          (util.stream-into-empty-buffer
            openai
            (prompts prompt-type)
            (core.str "runbook-" (core.get m selected) ".md")))))))

(comment
  (prompt-types)
  (prompts "github:docker/labs-make-runbook?ref=main&path=prompts/docker")
  (generate-runbook))

(nvim.create_user_command
  "GenerateRunbook"
  (fn [_] 
    (case (pcall generate-runbook)
      (true _) (core.println "GenerateRunbook completed")
      (false error) (core.println 
                        (vim.fn.printf "GenerateRunbook failed to run: %s" error))))
  {:desc "Generate a Runbook"})

