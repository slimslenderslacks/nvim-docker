(module notebook
  {autoload {nvim aniseed.nvim
             core aniseed.core
             string aniseed.string
             complaints complaints}})

(comment
  ;; list current tabpage nrs
  (vim.api.nvim_list_tabpages)
  ; current tabpage returns the tabnr identifier
  (vim.api.nvim_get_current_tabpage)
  ;; tabmoves can cause the tab numbers to change
  (vim.api.nvim_tabpage_set_var 2 "id" "notebook")
  (vim.api.nvim_tabpage_get_var 2 "id")
  ;; the tab number can be changed by moving tabs around (different from the nr)
  (vim.api.nvim_tabpage_get_number 2)
  ; get active window for tab page nr
  (vim.api.nvim_tabpage_get_win 2)
  ;; current windows on tab page
  (vim.api.nvim_tabpage_list_wins 0)
  ;; switch current tab page
  (vim.api.nvim_set_current_tabpage 2))

;; :nr :winnr :bufnr
(var docker-notebook {:count 0
                      :streaming nil})

(defn new-cell? [s]
  (let [streaming (. docker-notebook :streaming)]
    (or (not streaming)
        (not (= s streaming)))))

(defn now-streaming [s]
  (tset docker-notebook :streaming s))

(defn configure-buffer [bufnr]
  (vim.api.nvim_buf_set_name bufnr (core.str "./cells/" (. docker-notebook :count)))
  (set docker-notebook (core.assoc docker-notebook 
                                   :count (core.inc (. docker-notebook :count))))
  ;; TODO this usually does nothing because we set the buffer filetype manually and our 
  ;;      buffer names might not correspond to the filetype
  (vim.api.nvim_buf_call bufnr (fn [] (vim.api.nvim_cmd {:cmd "filetype"
                                                         :args ["detect"]} {})))
  (vim.api.nvim_buf_set_option bufnr "buftype" "nowrite")
  (vim.api.nvim_buf_set_option bufnr "wrap" true)
  
  bufnr)

(defn add-cell-buffer []
  ; create buffer - listed=true, scratch=false
  (let [bufnr (vim.api.nvim_create_buf false false)]
    (vim.api.nvim_win_set_buf (vim.api.nvim_get_current_win) bufnr)
    (configure-buffer bufnr)))

(defn notebook-create []
  (vim.api.nvim_cmd {:cmd "tabnew"} {})
  (let [tab-nr (vim.api.nvim_get_current_tabpage)]
    (vim.api.nvim_tabpage_set_var tab-nr "id" "notebook")
    (set docker-notebook (core.assoc docker-notebook 
                                     :nr tab-nr
                                     :winnr (vim.api.nvim_get_current_win)))
    (let [bufnr (vim.api.nvim_win_get_buf (vim.api.nvim_get_current_win))]
      (vim.api.nvim_buf_set_option bufnr "buflisted" false)
      bufnr)))

(defn notebook-add-cell [{:path path :language-id language-id &as opts}]
  (if (or 
        (not (. docker-notebook :nr))
        (not (vim.api.nvim_tabpage_is_valid (. docker-notebook :nr))))
    ;; missing notebook
    (let [bufnr (notebook-create)]
      (if (and path language-id)
        (do
          (vim.api.nvim_cmd {:cmd "edit" :args [path]} {}))
        (configure-buffer bufnr))
      bufnr)
    (do
      (when (not (vim.api.nvim_win_is_valid (. docker-notebook :winnr)))
        (set docker-notebook (core.assoc docker-notebook
                                         :winnr (core.last (vim.api.nvim_tabpage_list_wins (. docker-notebook :nr))))))
      ;; TODO optionally switch to the buffer
      ;;(vim.api.nvim_set_current_tabpage (. docker-notebook :nr))
      
        ;; TODO is this necessary?
      (vim.api.nvim_set_current_win (. docker-notebook :winnr))
      (vim.api.nvim_cmd {:cmd "sp"} {})
      (set docker-notebook 
           (core.assoc docker-notebook 
                       :winnr (vim.api.nvim_get_current_win)))
      (if (and path language-id)
        (do 
          (vim.api.nvim_cmd {:cmd "edit" :args [path]} {})
          (vim.api.nvim_get_current_buf))
        (add-cell-buffer)))))

;; what are some Docker Official Images for mysql that have more than 3 stars?
;; can you classify the mysql image for me?  Break it down based on who should use it and why they would use it.

(defn bottom-terminal [cmd]
  "split current window, create a term buffer in the split window, 
     and then open a command in that buffer"
  (let [current-win (nvim.tabpage_get_win 0)
        original-buf (nvim.win_get_buf current-win)
        term-buf (nvim.create_buf false true)]
    (vim.cmd "split")
    (let [new-win (nvim.tabpage_get_win 0)]
      (nvim.win_set_buf new-win term-buf)
      (nvim.fn.termopen cmd))))

(defn runBuffer []
  (let [bufnr (vim.api.nvim_get_current_buf)]
    (bottom-terminal
      (string.join "\n" (vim.api.nvim_buf_get_lines bufnr 0 -1 false)))))

(defn make-buf-runnable []
  (let [bufnr (vim.api.nvim_win_get_buf (. docker-notebook :winnr))]
    (vim.api.nvim_buf_set_keymap bufnr :n :<leader>run ":lua require('notebook').runBuffer()<CR>" {})))

(defn make-prompt-buf-runnable []
  (let [bufnr (vim.api.nvim_win_get_buf (. docker-notebook :winnr))]
    (vim.api.nvim_buf_set_keymap bufnr :n :<leader>run ":lua require('dockerai').runBufferPrompt()<CR>" {})))

(defn create-buffer-question []
  (notebook-add-cell {:language-id "dockerai"}) 
  (vim.api.nvim_buf_call (vim.api.nvim_win_get_buf (. docker-notebook :winnr)) (fn [] (set vim.bo.filetype "dockerai")))
  (make-prompt-buf-runnable))

(defn create-shell-script []
  (notebook-add-cell {:language-id "shellscript"}) 
  (vim.api.nvim_buf_call (vim.api.nvim_win_get_buf (. docker-notebook :winnr)) (fn [] (set vim.bo.filetype "shellscript")))
  (make-buf-runnable))

(defn resize []
  "optimize the window sizes for the current notebook tab"
  ;; table.remove removes the final entry
  (local wins (vim.api.nvim_tabpage_list_wins (. docker-notebook :nr)))
  (table.remove wins)
  (each [_ winnr (pairs wins)]
    (let [bufnr (vim.api.nvim_win_get_buf winnr)
          line-count (core.count (vim.api.nvim_buf_get_lines bufnr 0 -1 true))
          optimum-size (if (< line-count 8) (+ line-count 2) 10)]
      (vim.api.nvim_win_call 
        winnr 
        (fn [] (vim.api.nvim_cmd {:cmd "resize" :args [optimum-size]} {}))))))

(defn append-to-cell [s filetype]
  "Appends content to an existing buffer - resets the buffer filetype (filetype generally shouldn't change)
    prereq - docker notebook must have an active/valid window"
  (let [bufnr (vim.api.nvim_win_get_buf (. docker-notebook :winnr))
        content (string.join "\n" (vim.api.nvim_buf_get_lines bufnr 0 -1 false))
        lines (string.split (core.str content s) "\n")]
    (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
    (vim.api.nvim_buf_call bufnr (fn [] (set vim.bo.filetype filetype)))
    (resize)))

(defn show-tab-window-buffer []
  "show coordinates of the current tab/window/buffer"
  (core.println 
    (core.str 
      (vim.api.nvim_get_current_tabpage) "-" 
      (vim.api.nvim_get_current_win) "-" 
      (vim.api.nvim_get_current_buf) "\n"
      (vim.api.nvim_win_get_cursor (vim.api.nvim_get_current_win)) "\n"
      docker-notebook)))

;; log buffer is unlisted and is a scratch buffer
(var log-buffer (vim.api.nvim_create_buf false true))
(var log-window nil)
(vim.api.nvim_buf_set_name log-buffer "dockerai.log")
(vim.api.nvim_buf_set_option log-buffer "buftype" "nowrite")
(defn append-to-log [lines]
  (vim.api.nvim_buf_set_lines 
    log-buffer 
    (core.count (vim.api.nvim_buf_get_lines log-buffer 0 -1 false)) 
    -1 false lines))

(defn toggle-log []
  (if log-window
    (do
      (vim.api.nvim_win_close log-window true)
      (set log-window nil))
    (do
      (vim.api.nvim_cmd {:cmd "vsplit"} {})
      (set log-window (vim.api.nvim_get_current_win)))))

(vim.api.nvim_create_user_command "NotebookAddCell" (partial notebook-add-cell {}) {:nargs 0})
(vim.api.nvim_create_user_command "NotebookCoordinates" show-tab-window-buffer {:nargs 0})
(vim.api.nvim_create_user_command "NotebookResize" resize {:nargs 0}) 
(vim.api.nvim_create_user_command "NotebookAddPromptCell" create-buffer-question {:nargs 0})
(vim.api.nvim_create_user_command "NotebookAddShellScript" create-shell-script {:nargs 0})
(vim.api.nvim_create_user_command "NotebookToggleLog" toggle-log {:nargs 0})
(nvim.set_keymap :n :<leader>log ":NotebookToggleLog<CR>" {})

(defn flush-function-call []
  "flush current command"
  (when (. docker-notebook :current-function-call) 
    (let [{:name name :arguments args} (. docker-notebook :current-function-call)
          ;; are these sometimes ready without parsing
          arguments (if (core.table? args) args (vim.json.decode args))]
      (append-to-log [(core.str "--- call function " name)])
      (append-to-log (core.concat [(core.str "--- arguments ")]
                                  (string.split (core.str arguments) "\n")))
      (if
        (or
          (= name "cell-execution")
          (= name "suggest-command"))
        (do 
          (notebook-add-cell {})
          (append-to-cell (. arguments :command) "shellscript")
          (make-buf-runnable))

        (= name "update-file")
        (let [{:languageId language-id :path path :edit edit} arguments
              bufnr 
              ;; read contents of file into cmp_buffer
              (notebook-add-cell {:path path :language-id language-id})]
          ;; TODO if the file doesn't exist, populate it!
          (core.println (pcall vim.api.nvim_buf_set_lines bufnr 0 0 false (string.split edit "\n")))
          ;; TODO add complaint back
          ;; (complaints.complain arguments)
          )

        (= name "show-notification")
        (let [{:level level :message message} arguments]
          ;; neovim supports TRACE DEBUG INFO WARN ERROR OFF
          ;; DEBUG INFO WARNING ERROR
          (vim.api.nvim_notify message vim.log.levels.INFO {}))
        
        (= name "create-notebook")
        (let [{:notebook notebook :cells cells} arguments]
          (each [_ {:kind kind :value value :languageId language-id} (pairs (. cells :cells))]
            (notebook-add-cell {})
            (if (= kind 1)
              (append-to-cell value "markdown")
              (do
                (append-to-cell value language-id)
                (when (= language-id "shellscript")
                  (make-buf-runnable))))))))
    (tset docker-notebook :current-function-call nil)))

(defn docker-ai-content-handler [extension-id message]
  "handles streaming messages from Docker AI"
  
  ;; process inbound messages
  (if 
    ;; new content for a cell
    (. message :content)
    (do
      (when (new-cell? :content)
        (notebook-add-cell {})
        (now-streaming :content)
        (flush-function-call))
      (append-to-cell (. message :content) "markdown"))

    ;; complete
    (. message :complete)
    (do
      (now-streaming nil)
      (flush-function-call)) 

    ;; starting a show-notification function-call which does not need a new-cell
    (let [call-name (-> message (. :function_call) (. :name))]
      (= call-name "show-notification"))
    (let [function-call-name (-> message (. :function_call) (. :name))]
      (when (new-cell? function-call-name)
        (now-streaming function-call-name)
        (flush-function-call))
      (set docker-notebook (core.assoc docker-notebook :current-function-call (. message :function_call))))  

    ;; any other function-call with a name
    (-> message (. :function_call) (. :name))
    (let [function-call-name (-> message (. :function_call) (. :name))]
      (when (new-cell? function-call-name)
        (now-streaming function-call-name)
        (flush-function-call))
      (set docker-notebook (core.assoc docker-notebook :current-function-call (. message :function_call))))  

    ;; any function-call with only arguments
    (and 
      (. message :function_call) 
      (let [{:name name :arguments arguments} (. message :function_call)]
        (and arguments (not name))))
    (let [current-function-call (. docker-notebook :current-function-call)
          {:name name :arguments arguments} (. message :function_call)]
      (set docker-notebook 
           (core.assoc docker-notebook 
                       :current-function-call 
                       (core.assoc 
                         current-function-call 
                         :arguments 
                         (core.str (. current-function-call :arguments) arguments)))))  

    ;; default - show json payload in current cell buffer
    (do
      (notebook-add-cell {})
      (append-to-cell (vim.json.encode message) "json"))))

(comment
  (core.println docker-notebook)
  (docker-ai-content-handler nil {:content "some content"})
  (docker-ai-content-handler nil {:content "\nsome more content"})
  (docker-ai-content-handler nil {:complete true})
  
  ;; add file complaint 
  (docker-ai-content-handler nil {:function_call {:name "update-file" :arguments {:languageId "dockerfile"
                                                                                  :path "Dockerfile"
                                                                                  :edit "FROM your ass"}}})
  (docker-ai-content-handler nil {:complete true})

  ;; show-notification
  (docker-ai-content-handler nil {:function_call {:name "show-notification" :arguments {:message "test message" :level "INFO"}}})
  (docker-ai-content-handler nil {:complete true})

  ;; cell-execution
  (docker-ai-content-handler nil {:function_call {:name "cell-execution" :arguments ""}})
  (docker-ai-content-handler nil {:function_call 
                                  {:arguments (vim.json.encode 
                                                {:command "docker build"})}})
  (docker-ai-content-handler nil {:complete true})

  ;; create-notebook
  (docker-ai-content-handler nil {:function_call {:name "create-notebook" 
                                                  :arguments
                                                  {:cells 
                                                   {:cells 
                                                    [{:kind 1 :value "Some Content"}
                                                     {:kind 2 :value "touch .dockerignore" :languageId "shellscript"}]}}}})

  (docker-ai-content-handler nil {:complete true})

  )

