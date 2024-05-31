(module copilot
  {autoload {core aniseed.core
            nvim aniseed.nvim
            str aniseed.string
            util slim.nvim
            curl plenary.curl}})

(defn open [lines]
  (let [buf (vim.api.nvim_create_buf false true)]
    (vim.api.nvim_buf_set_text buf 0 0 0 0 lines)
    (util.open-win buf {:title "Copilot"})))

(comment
  (open ["hey"]))

(defn openselection []
  (open (util.get-current-buffer-selection)))

(nvim.set_keymap :v :<leader>ai ":lua require('copilot').openselection()<CR>" {})

;; -------

(defn ollama [system-prompt prompt cb]
  (curl.post
    "http://localhost:11434/api/generate"
    {:body (vim.json.encode {:model "mistral"
                             :prompt prompt
                             :system-prompt system-prompt
                             :stream true})
     :stream (fn [_ chunk _]
               (cb (. (vim.json.decode chunk) "response"))) }))

(defn execute-prompt [prompt]
  (util.stream-into-buffer (partial ollama "") prompt))

(comment
  (execute-prompt "What does a Dockerfile look like?")
  (vim.fn.input "Question:"))

(defn copilot []
  (let [prompt (..
                 "I have a question about this: "
                 (vim.fn.input "Question: ")
                 "\n\n Here is the code:\n```\n"
                 (str.join "\n" (util.get-current-buffer-selection))
                 "\n```\n")]
    (execute-prompt prompt)))

(nvim.set_keymap :v :<leader>ai ":lua require('copilot').copilot()<CR>" {})

;; I need a function that adds strings in python
;; My Docker Image should package a NOde app based on a package.json file

;; ------------

