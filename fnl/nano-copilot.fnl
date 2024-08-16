(module nano-copilot
  {autoload {core aniseed.core
             nvim aniseed.nvim
             str aniseed.string
             util slim.nvim
             curl plenary.curl
             lsps lsps}
   require {job plenary.job}})

(defn open [lines]
  (let [buf (vim.api.nvim_create_buf false true)]
    (nvim.buf_set_text buf 0 0 0 0 lines)
    (util.open-win buf {:title "Copilot"})))

(comment
  (open ["hey"]))

(defn openselection []
  (open (util.get-current-buffer-selection)))

;(nvim.set_keymap :v :<leader>ai ":lua require('nano-copilot').openselection()<CR>" {})

;;; --------

(defn ollama [system-prompt prompt cb]
  (curl.post
    "http://localhost:11434/api/generate"
    {:body (vim.json.encode {:model "llama3.1"
                             :prompt prompt
                             :system system-prompt
                             :stream true})
     :stream (fn [_ chunk _]
               (cb (. (vim.json.decode chunk) "response")))}))

(defn execute-prompt [prompt]
  (util.stream-into-buffer (partial ollama "") prompt))

(comment
  (execute-prompt "What does a Dockerfile look like?")
  (vim.fn.input "Question: "))

;; ----------

(defn copilot []
  (let [prompts ["ask"
                 "ask about snippet"]]
    (vim.ui.select
      prompts
      {:prompt "Select LLM"}
      (fn [selected _]
          (if
            (= selected "ask about snippet")
            (execute-prompt
                     (..
                       "\n\n Here is a code snippet that I'm working on:\n```\n"
                       (str.join "\n" (util.get-current-buffer-selection))
                       "\n```\n\n"
                       (vim.fn.input "Ask Assistant: ")))
            (execute-prompt (str.join "\n" (util.get-current-buffer-selection))))))))

(nvim.set_keymap :v :<leader>ai ":lua require('nano-copilot').copilot()<CR>" {})

;; I need a function that adds strings in python
;; My Docker Image should package a Node app based on a package.json file

;; ----------------

(comment
  (lsps.list))

