(module prompts.runner
  {autoload {core aniseed.core
             nvim aniseed.nvim
             curl plenary.curl
             fs aniseed.fs
             str aniseed.string
             util slim.nvim
             rpc vim.lsp.rpc
             jsonrpc jsonrpc}})

(var debug false)
(var use-docker false)
(var hostdir nil)

(defn update-buffer [m message-callback functions-callback]
  (case m
    {:method "start" :params x} (message-callback
                                  (string.format
                                    "\n%s ROLE %s%s\n"
                                    (faccumulate [s "" i 0 (core.inc (core.get x "level"))]
                                      (core.str s "#"))
                                    (core.get x "role")
                                    (let [s (core.get x "content")]
                                      (if s (string.format "(%s)" s) ""))))
    {:method "message" :params x} (if (core.get x "content")
                                    (message-callback (core.get x "content"))
                                    debug
                                    (message-callback (core.get x "debug"))
                                    (message-callback (core.get x "content")))
    {:method "functions" :params x} (functions-callback (core.str x))
    {:method "functions-done" :params x} (functions-callback (core.str "\n"))
    {:method "prompts" :params x} (message-callback "")
    {:method "error" :params x} (do
                                  (message-callback (string.format "\n```error\n%s\n```\n" (core.get x "content")))
                                  (if (and debug (core.get x "exception"))
                                    (message-callback (core.get x "exception"))))
    ;; message parsing error
    {:error err :data d} (message-callback
                           (core.str (string.format "\nerr--> %s\n%s" err d)))

    _ (message-callback (core.str "-->\n" data))))

(defn prompt-runner
  [args message-callback functions-callback]
  "Run the prompt runner docker container with the given args.
   assume stdout will have blocks of json-rpc notifications
   which could be either stream responses or streaming function calls"
  ;; look at passing :text true to convert /r/n to /n
  (rpc.start
    args
    {:notification (fn [method params]
                     (update-buffer
                       {:method method :params params}
                       message-callback
                       functions-callback))}
    {:cwd "/Users/slim/docker/labs-ai-tools-for-devs/"}))

(defn basedir []
  (vim.fn.fnamemodify (vim.api.nvim_buf_get_name 0) ":h"))

(defn relativize [base f]
  (vim.fn.fnamemodify f ":."))

(defn getHostdir []
  (or hostdir (vim.fn.getcwd)))

(comment
  (get-hostdir)
  (core.println hostdir))

(defn docker-command [f]
                     ["docker"
                      "run"
                      "--rm"
                      "-v" "/var/run/docker.sock:/var/run/docker.sock"
                      "-v" "/run/host-services/backend.sock:/lsp-server/docker-desktop-backend.sock"
                      "-e" "DOCKER_DESKTOP_SOCKET_PATH=/lsp-server/docker-desktop-backend.sock"
                      "-e" "OPENAI_API_KEY_LOCATION=/root"
                      "--mount" "type=volume,source=docker-prompts,target=/prompts"
                      "--mount" "type=bind,source=/Users/slim/.openai-api-key,target=/root/.openai-api-key"
                      "--mount" (string.format "type=bind,source=%s,target=/app/workdir" (vim.fn.getcwd))
                      "--workdir" "/app/workdir"
                      "vonwig/prompts:latest"
                      "run"
                      "--jsonrpc"
                      "--host-dir" (getHostdir)
                      "--platform" "darwin"
                      "--prompts-file" (relativize (vim.fn.getcwd) f)])

(defn bb-command [f]  ["clj"
                       "-M:main"
                       "run"
                       "--jsonrpc"
                       "--host-dir" (getHostdir)
                       "--platform" "darwin"
                       "--thread-id" "thread"
                       "--prompts-file" f])

(defn bb-prompt-command [f]
                      ["clj"
                       "-M:main"
                       "--jsonrpc"
                       "--host-dir" (getHostdir)
                       "--platform" "darwin"
                       "--prompts-file" f])

(defn execute-prompt [type]
  "execute the prompt runner and stream notifications to a vim buffer"
  (vim.cmd "split")
  (vim.cmd "resize +10")
  (util.start-streaming
    (fn [messages-callback functions-callback]
      (prompt-runner (core.concat
                       (docker-command)
                       ["--prompts" type]
                       (if debug ["--debug"] []))
                     messages-callback
                     functions-callback))))

(defn execute-local-prompt-without-docker []
  "execute the prompt runner and stream notifications to a vim buffer"
  (let [f (vim.api.nvim_buf_get_name 0)]
    (vim.cmd "split")
    (vim.cmd "resize +10")
    (util.start-streaming
      (fn [messages-callback functions-callback]
        (prompt-runner (core.concat
                         (if use-docker (docker-command f) (bb-command f))
                         (if debug ["--debug"] []))
                       messages-callback
                       functions-callback) ))))

(defn execute-local-prompt-generate []
  "execute the prompt runner and stream notifications to a vim buffer"
  (let [f (vim.api.nvim_buf_get_name 0)]
    (vim.cmd "split")
    (vim.cmd "resize +10")
    (util.start-streaming
      (fn [messages-callback functions-callback]
        (prompt-runner (core.concat
                         (bb-prompt-command f)
                         (if debug ["--debug"] []))
                       messages-callback
                       functions-callback) ))))

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

(defn localPromptList
  []
  "select a prompt git ref and execute the prompt"
  (execute-local-prompt-generate))

(def promptRun prompt-run)

(comment
  (prompt-run))

(nvim.set_keymap :n :<leader>assist ":lua require('prompts.runner').promptRun()<CR>" {})
(nvim.set_keymap :n :<leader>pr ":lua require('prompts.runner').localPromptRun()<CR>" {})
(nvim.set_keymap :n :<leader>pl ":lua require('prompts.runner').localPromptList()<CR>" {})

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
  "PromptsToggleUseDocker"
  (fn [_]
    (set use-docker (not use-docker))
    (core.println (core.str "use-docker " use-docker)))
  {:desc "toggle prompts use of docker"
   :nargs 0})

(nvim.create_user_command
  "PromptsGetConfigr"
  (fn [_]
    (core.println (string.format "HostDir: %s\nDebug: %s\nUseDocker: %s\n"
                                 (getHostdir)
                                 debug
                                 use-docker)))
  {:desc "get prompts hostdir"
   :nargs 0})

