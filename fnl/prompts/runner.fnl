(module prompts.runner
  {autoload {core aniseed.core
             nvim aniseed.nvim
             curl plenary.curl
             fs aniseed.fs
             str aniseed.string
             util slim.nvim
             jsonrpc jsonrpc}})

(var debug false)

(defn prompt-runner
  [args message-callback functions-callback]
  "Run the prompt runner docker container with the given args.
   assume stdout will have blocks of json-rpc notifications
   which could be either stream responses or streaming function calls"
  (vim.system
    args
    {:text true
     :cwd "/Users/slim/docker/labs-ai-tools-for-devs/"
     :stdin false
     :stdout (fn [err data]
               (core.map (fn [m]
                           (case m
                             {:method "message" :params x} (if (core.get x "content")
                                                             (message-callback (core.get x "content"))
                                                             debug
                                                             (message-callback (core.get x "debug"))
                                                             (message-callback (core.get x "content")))
                             {:method "functions" :params x} (functions-callback (core.str x))
                             {:method "functions-done" :params x} (functions-callback (core.str "\n"))
                             {:error err :data d} (message-callback (core.str (string.format "\nerr--> %s\n%s" err d)))
                             {:method "prompts" :params x} (message-callback "")
                             _ (message-callback (core.str "-->\n" data))))
                         (if data
                           (jsonrpc.messages data)
                           [])))
     :stderr (fn [err data]
               (message-callback data))}
    (fn [{:code code :signal signal &as data}])))

(defn execute-prompt [type]
  "execute the prompt runner and stream notifications to a vim buffer"
  (util.start-streaming
    (fn [messages-callback functions-callback]
      (prompt-runner ["docker"
                      "run"
                      "--rm"
                      "-v" "/var/run/docker.sock:/var/run/docker.sock"
                      "--mount" "type=volume,source=docker-prompts,target=/prompts"
                      "--mount" (string.format "type=bind,source=%s,target=/project" (vim.fn.getcwd))
                      "--mount" "type=bind,source=/Users/slim/.openai-api-key,target=/root/.openai-api-key"
                      "vonwig/prompts:local"
                      "run"
                      "--jsonrpc"
                      "--host-dir" (vim.fn.getcwd)
                      "--user" "jimclark106"
                      "--platform" "darwin"
                      "--prompts" type]
                     messages-callback
                     functions-callback))))

(defn basedir []
  (vim.fn.fnamemodify (vim.api.nvim_buf_get_name 0) ":h"))

(var hostdir "/Users/slim/docker/labs-make-runbook/")

(defn getHostdir []
  hostdir)

(comment
  (get-hostdir)
  (core.println hostdir))

(defn execute-local-prompt-without-docker []
  "execute the prompt runner and stream notifications to a vim buffer"
  (let [f (vim.api.nvim_buf_get_name 0)]
    (vim.cmd "split")
    (vim.cmd "resize +10")
    (util.start-streaming
      (fn [messages-callback functions-callback]
        (let [args (core.concat
                     ["bb"
                      "-m"
                      "prompts"
                      "run"
                      "--jsonrpc"
                      "--host-dir" (getHostdir)
                      "--user" "jimclark106"
                      "--platform" "darwin"
                      "--thread-id" "thread"
                      "--prompts-file" f]
                     (if debug ["--debug"] []))]
          (prompt-runner args
                         messages-callback
                         functions-callback))))))

(defn prompt-run
  []
  "select a prompt git ref and execute the prompt"
  (let [prompts ["github:docker/labs-githooks?ref=main&path=prompts/git_hooks_just_llm"
                 "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_with_linguist"
                 "github:docker/labs-githooks?ref=main&path=prompts/git_hooks"
                 "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_single_step"
                 "github:docker/labs-make-runbook?ref=main&path=prompts/dockerfiles"]]
    (vim.ui.select
      prompts
      {:prompt "Select LLM"}
      (fn [selected _]
        (execute-prompt selected)))))

(defn localPromptRun
  []
  "select a prompt git ref and execute the prompt"
  (execute-local-prompt-without-docker))

(def promptRun prompt-run)

(comment
  (prompt-run))

(nvim.set_keymap :n :<leader>assist ":lua require('prompts.runner').promptRun()<CR>" {})
(nvim.set_keymap :n :<leader>pr ":lua require('prompts.runner').localPromptRun()<CR>" {})

(nvim.create_user_command
  "PromptsSetHostdir"
  (fn [{:args args}]
    (set hostdir args))
  {:desc "set prompts hostdir"
   :nargs 1
   :complete "dir"})

(nvim.create_user_command
  "PromptsToggleDebug"
  (fn [_]
    (set debug (not debug))
    (core.println (core.str "debug " debug)))
  {:desc "toggle prompts debug"
   :nargs 0})

(nvim.create_user_command
  "PromptsGetHostdir"
  (fn [_]
    (core.println (core.str "HostDir: " (getHostdir))))
  {:desc "get prompts hostdir"
   :nargs 0})

