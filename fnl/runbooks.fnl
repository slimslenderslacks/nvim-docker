(module runbooks
  {autoload {core aniseed.core
             nvim aniseed.nvim
             curl plenary.curl
             fs aniseed.fs
             string aniseed.string
             util slim.nvim}})

(def opena-api-key (string.trim (core.slurp "/Users/slim/.open-api-key")))

(defn prompt-types []
  (let [obj (vim.system 
              ["docker" "run"
               "--rm"
               "-v" "/var/run/docker.sock:/var/run/docker.sock"
               "vonwig/prompts:latest"
               "prompts"]
              {:text true})
        {:stdout out} (obj.wait obj)]
    (->> 
      (vim.json.decode out)
      (core.reduce (fn [agg {:title title :type type}]
                     (core.assoc agg title type)) {}))))

(defn prompts [type]
  (let [obj (vim.system 
              ["docker" "run"
               "--rm"
               "-v" "/var/run/docker.sock:/var/run/docker.sock"
               "--mount"
               "type=volume,source=docker-prompts,target=/prompts"
               "vonwig/prompts:latest"
               (vim.fn.getcwd)
               "jimclark106"
               "darwin"
               type]
              {:text true})
        {:stdout out :stderr err} (obj.wait obj)]
    (vim.json.decode out)))

(defn openai [messages cb]
  (curl.post 
    "https://api.openai.com/v1/chat/completions"
    {:body (vim.json.encode {:model "gpt-4"
                             :messages messages
                             :stream true})
     :headers {:Authorization (core.str "Bearer " opena-api-key)
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
  (prompt-types)
  (prompts "docker")
  (util.stream-into-empty-buffer openai (prompts "docker"))
  (openai (prompts "docker") (fn [s] (core.println s))))

(defn generate-runbook [_]
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
  (generate-runbook nil))

(nvim.create_user_command 
  "GenerateRunbook"
  generate-runbook
  {:desc "Generate a Runbook"})
