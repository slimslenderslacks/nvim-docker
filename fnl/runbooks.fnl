(module runbooks
  {autoload {core aniseed.core
             nvim aniseed.nvim
             curl plenary.curl
             fs aniseed.fs
             str aniseed.string
             util slim.nvim}})

(defn parse-git-ref [s]
  (case-try s
    s (vim.split s "?")
    [ref ?opts] (case (string.match ref "github:(%S+)/(%S+)")
                  (owner repo) [{:owner owner :repo repo} ?opts])
    [m ?opts] (if ?opts 
                (core.reduce (fn [agg s]
                               (let [[k v] (vim.split s "=")]
                                 (core.assoc agg k v)))
                             m 
                             (vim.split ?opts "&"))
                m)))

(comment
  (parse-git-ref "github:docker/labs-make-runbook?ref=main&path=prompts/docker")
  (parse-git-ref "github:docker/labs-make-runbook")
  (parse-git-ref "alskfj"))

(defn opena-api-key []
  (or (case (core.slurp (vim.fn.printf "%s/.open-api-key" (os.getenv "HOME")))
        s (str.trim s))
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
                 "--mount" "type=volume,source=docker-prompts,target=/prompts"
                 "vonwig/prompts:latest"
                 "prompts"])))

(defn prompt-runner 
  [args callback]
  (vim.system 
    args
    {:text true 
     :stdin false 
     :stdout (fn [err data]
               (callback data))
     :stderr (fn [err data]
               (callback data))}
    (fn [{:code code :signal signal &as data}])))

(defn execute-prompt [type]
  (util.start-streaming
    (fn [callback]
      (prompt-runner ["docker"
                      "run"
                      "--rm"
                      "-v" "/var/run/docker.sock:/var/run/docker.sock"
                      "--mount" "type=volume,source=docker-prompts,target=/prompts"
                      "--mount" (string.format "type=bind,source=%s,target=/project" (vim.fn.getcwd))
                      "--mount" "type=bind,source=/Users/slim/.openai-api-key,target=/root/.openai-api-key"
                      "vonwig/prompts:latest"
                      "run"
                      (vim.fn.getcwd)
                      "jimclark106"
                      "darwin"
                      type]
                     callback))))

(defn prompt-run
  []
  (let [prompts ["github:docker/labs-githooks?ref=main&path=prompts/git_hooks_just_llm"
                 "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_with_linguist"
                 "github:docker/labs-githooks?ref=main&path=prompts/git_hooks"
                 "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_single_step"]]
    (vim.ui.select
      prompts
      {:prompt "Select LLM"}
      (fn [selected _]
        (let [prompt (vim.fn.input "Prompt: ")]
          (execute-prompt selected))))))

(def promptRun prompt-run)

(comment
  (prompt-run))

(nvim.set_keymap :n :<leader>assist ":lua require('runbooks').promptRun()<CR>" {})

(defn register-runbook-type [t]
  (docker-run ["docker" 
                 "run"
                 "--rm"
                 "-v" "/var/run/docker.sock:/var/run/docker.sock"
                 "--mount" "type=volume,source=docker-prompts,target=/prompts"
                 "vonwig/prompts:latest"
                 "register" t]))

(defn unregister-runbook-type [t]
  (docker-run ["docker" 
                 "run"
                 "--rm"
                 "-v" "/var/run/docker.sock:/var/run/docker.sock"
                 "--mount" "type=volume,source=docker-prompts,target=/prompts"
                 "vonwig/prompts:latest"
                 "unregister" t]))

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

(defn generate-friendly-prompt-name [prompt-type]
  (case (parse-git-ref prompt-type)
    {:repo repo :path path} (string.format "runbook.gh-%s-%s.md" repo (string.gsub path "/" "-"))
    {:repo repo} (vim.fn.printf "runbook.gh-%s.md" repo)
    _ (vim.fn.printf "runbook.%s.md" prompt-type)))

(comment
  (generate-friendly-prompt-name "github:docker/labs-make-runbook?ref=main&path=prompts/docker")
  (generate-friendly-prompt-name "whatever"))

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
            (generate-friendly-prompt-name (core.get m selected))))))))

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

(nvim.create_user_command
  "RunbookRegister"
  (fn [{:args args}] 
    (case (pcall register-runbook-type args)
      (true _) (core.println "RunbookRegister successful")
      (false error) (core.println 
                        (vim.fn.printf "RunbookRegister failed to run: %s" error))))
  {:desc "Register a Runbook"
   :nargs 1})

(nvim.create_user_command
  "RunbookUnregister"
  (fn [{:args args}] 
    (case (pcall unregister-runbook-type args)
      (true _) (core.println "RunbookUnregister successful")
      (false error) (core.println 
                        (vim.fn.printf "RunbookUnregister failed to run: %s" error))))
  {:desc "Unregister a Runbook"
   :nargs 1})

