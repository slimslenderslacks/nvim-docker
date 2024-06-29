(module prompts.runner
  {autoload {core aniseed.core
             nvim aniseed.nvim
             curl plenary.curl
             fs aniseed.fs
             str aniseed.string
             util slim.nvim
             jsonrpc jsonrpc}} )

(defn prompt-runner
  [args message-callback functions-callback]
  "Run the prompt runner docker container with the given args.
   assume stdout will have blocks of json-rpc notifications
   which could be either stream responses or streaming function calls"
  (vim.system 
    args
    {:text true 
     :stdin false 
     :stdout (fn [err data]
               (core.map (fn [m] 
                           (case m 
                             {:method "message" :params x} (message-callback (core.get x "content")) 
                             {:method "functions" :params x} (functions-callback (core.str x)) 
                             {:method "functions-done" :params x} (functions-callback (core.str x)) 
                             {:error err :data d} (message-callback (core.str (string.format "%s\n%s" err d))) 
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
                      (vim.fn.getcwd)
                      "jimclark106"
                      "darwin"
                      type]
                     messages-callback
                     functions-callback))))

(defn prompt-run
  []
  "select a prompt git ref and execute the prompt"
  (let [prompts ["github:docker/labs-githooks?ref=main&path=prompts/git_hooks_just_llm"
                 "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_with_linguist"
                 "github:docker/labs-githooks?ref=main&path=prompts/git_hooks"
                 "github:docker/labs-githooks?ref=slim/prompts/input&path=prompts/git_hooks_single_step"]]
    (vim.ui.select
      prompts
      {:prompt "Select LLM"}
      (fn [selected _]
        (execute-prompt selected)
        ;(let [prompt (vim.fn.input "Prompt: ")]
          ;(execute-prompt selected))
        ))))

(def promptRun prompt-run)

(comment
  (prompt-run))

(nvim.set_keymap :n :<leader>assist ":lua require('prompts.runner').promptRun()<CR>" {})


