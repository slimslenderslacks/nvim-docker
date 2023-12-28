(module notebook
  {autoload {nvim aniseed.nvim
             core aniseed.core
             string aniseed.string}})

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

(defn add-cell-buffer []
  (let [bufnr (vim.api.nvim_create_buf true false)]
    (vim.api.nvim_buf_set_name bufnr (core.str "./cells/" (. docker-notebook :count)))
    (vim.api.nvim_win_set_buf (vim.api.nvim_get_current_win) bufnr)
    (vim.api.nvim_buf_call bufnr (fn [] (vim.api.nvim_cmd {:cmd "filetype"
                                                           :args ["detect"]} {})))
    (set docker-notebook (core.assoc docker-notebook 
                                     :winnr (vim.api.nvim_get_current_win)
                                     :count (core.inc (. docker-notebook :count))))
    bufnr))

(defn notebook-create []
  (vim.api.nvim_cmd {:cmd "tabnew"} {})
  (let [tab-nr (vim.api.nvim_get_current_tabpage)]
    (vim.api.nvim_tabpage_set_var tab-nr "id" "notebook")
    (set docker-notebook (core.assoc docker-notebook :nr tab-nr))))

(defn notebook-add-cell []
  (if (not (. docker-notebook :nr))
    ;; missing notebook
    (do
      (notebook-create)
      (add-cell-buffer))
    (do
      (vim.api.nvim_set_current_tabpage (. docker-notebook :nr))
      (when (. docker-notebook :winnr)
        (vim.api.nvim_set_current_win (. docker-notebook :winnr)))
      (let [buf-nr (vim.api.nvim_create_buf false true)]
        (vim.api.nvim_cmd {:cmd "sp"} {})
        ;; buf is listed and not scratch
        (add-cell-buffer)))))

(defn append-to-cell [s filetype]
  ""
  (let [bufnr (vim.api.nvim_win_get_buf (. docker-notebook :winnr))
        content (string.join "\n" (vim.api.nvim_buf_get_lines bufnr 0 -1 false))]
    (vim.api.nvim_buf_set_lines bufnr 0 -1 false (string.split (core.str content s) "\n"))
    (vim.api.nvim_buf_call bufnr (fn [] (set vim.bo.filetype filetype)))))

(defn show-tab-window-buffer []
  (core.println 
    (core.str 
      (vim.api.nvim_get_current_tabpage) "-" 
      (vim.api.nvim_get_current_win) "-" 
      (vim.api.nvim_get_current_buf) "\n"
      (vim.api.nvim_win_get_cursor (vim.api.nvim_get_current_win)) "\n"
      docker-notebook)))

(vim.api.nvim_create_user_command "NotebookAddCell" notebook-add-cell {:nargs 0})
(vim.api.nvim_create_user_command "NotebookCoordinates" show-tab-window-buffer {:nargs 0})

;; create a new docker notebook tab
;; each shellscript/markdown content is loaded into a buffer with a window 
;; window stack can't be changed 
;; new windows always show all of the height - existing windows can be shrunk
;; buffers can be edited and all have files in some local docker directory
;; add a command that will run whatever is in the selected shellscript buffer 
;; will need a NotebookScrollUp/NotebookScrollDown command to shuffle tab page window selections
;; will need a NotebookAddCell comand to append a new cell
;; will need a NotebookCreate command to start a new one

;; different messages will need to be streamed into different notebook cells 
;; the message has to go into a stateful thing
;;   - some messages can write directly to some cell buffer
;;   - other messages will build up a function call and only the final
;;     function call will update a cell buffer
;; get a notebook object
;; use a content-handler that has a reference to this notebook

(defn flush-function-call []
  "flush current command"
  (when (. docker-notebook :current-function-call) 
    (let [{:name name :arguments args} (. docker-notebook :current-function-call)
          ;; are these sometimes ready without parsing
          arguments (if (core.table? args) args (vim.json.decode args))]
      (if
        (or
          (= name "cell-execution")
          (= name "suggest-command"))
        (do 
          (notebook-add-cell)
          ;; TODO make cell shellscript filetype buffer
          (append-to-cell (. arguments :command) "shellscript"))

        (= name "update-file")
        (do
          (notebook-add-cell)
          ;; read contents of file into cmp_buffer
          ;; add complaint
          (append-to-cell (core.str "not complete") "markdown"))

        (= name "show-notification")
        (let [{:level level :message message} arguments]
          ;; neovim supports TRACE DEBUG INFO WARN ERROR OFF
          ;; DEBUG INFO WARNING ERROR
          (vim.api.nvim_notify message vim.log.levels.INFO {}))
        
        (= name "create-notebook")
        (let [{:notebook notebook :cells cells} arguments]
          (each [_ {:kind kind :value value :languageId language-id} (pairs (. cells :cells))]
            (notebook-add-cell)
            (if (= kind 1)
              (append-to-cell value "markdown")
              (append-to-cell value language-id))))))
    (tset docker-notebook :current-function-call nil)))

(defn docker-ai-content-handler [extension-id message]
  "handles streaming messages from Docker AI"
  
  ;; process inbound messages
  (if 
    ;; new content for a cell
    (. message :content)
    (do
      (when (new-cell? :content)
        (notebook-add-cell)
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
      (notebook-add-cell)
      (append-to-cell (vim.json.encode message) "json"))))

(comment
  (core.println docker-notebook)
  (docker-ai-content-handler nil {:content "some content"})
  (docker-ai-content-handler nil {:content "\nsome more content"})
  ;; show-notification
  (docker-ai-content-handler nil {:complete true})
  (docker-ai-content-handler nil {:function_call {:name "show-notification" :arguments {:message "test message" :level "INFO"}}})
  (docker-ai-content-handler nil {:complete true})
  (core.println docker-notebook)
  ;; cell
  (docker-ai-content-handler nil {:function_call {:name "cell-execution" :arguments ""}})
  (docker-ai-content-handler nil {:function_call 
                                  {:arguments (vim.json.encode 
                                                {:command "docker build"})}})
  (docker-ai-content-handler nil {:complete true})

  (docker-ai-content-handler nil {:function_call {:name "create-notebook" 
                                                  :arguments
                                                  {:cells 
                                                   {:cells 
                                                    [{:kind 1 :value "Some Content"}
                                                     {:kind 2 :value "touch .dockerignore" :languageId "shellscript"}]}}}})

  (docker-ai-content-handler nil {:complete true})

  )

