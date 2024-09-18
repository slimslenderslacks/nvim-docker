(module slim.nvim
  {autoload {nvim aniseed.nvim
             core aniseed.core
             str aniseed.string
             lspconfig-util lspconfig.util}})

(defn decode-payload [s]
  (vim.json.decode
    (vim.base64.decode (.. (. (vim.split s "." {:plain true}) 2) "="))))

(defn update-buf [buf lines]
  (vim.api.nvim_buf_call
    buf
    (fn []
      (vim.cmd "norm! G")
      (vim.api.nvim_put lines "" true true))))

(defn git-root []
  (or
    ((lspconfig-util.root_pattern ".git") (vim.fn.getcwd))
    (vim.fn.getcwd)))

(defn get-current-buffer-selection []
  (let [[_ s1 e1 _] (nvim.fn.getpos "'<")
        [_ s2 e2 _] (nvim.fn.getpos "'>")]
    (nvim.buf_get_text (nvim.buf.nr) (- s1 1) (- e1 1) (- s2 1) (- e2 1) {})))

(def floating-win-opts
  {:relative "editor"
   :row 3
   :col 3
   :width 80
   :height 35
   :style "minimal"
   :border "rounded"
   :title "my title"
   :title_pos "center"})

(defn open-win [buf opts]
  ;; merge in floating-in-opts using core.merge to make this if we want a floating window
  (let [win (nvim.open_win buf true (core.merge {:win 0 :split "below"} opts))]
    (nvim.set_option_value "filetype" "markdown" {:buf buf})
    (nvim.set_option_value "buftype" "nofile" {:buf buf})
    (nvim.set_option_value "wrap" true {:win win})
    (nvim.set_option_value "linebreak" true {:win win})
    win))

(defn show-spinner [buf n]
  (var current-char 1)
  (let [characters ["⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"]
        format "> Generating %s"
        t (vim.loop.new_timer)]
    (t:start 100 100 (vim.schedule_wrap
                       (fn []
                         (let [lines [(format:format (core.get characters current-char))]]
                           (nvim.buf_set_lines buf n (+ n 1) false lines)
                           (set current-char (+ (% current-char (core.count characters)) 1))))))
    t))

(defn uuid []
  (let [p (vim.system
            ["uuidgen"]
            {:text true})
        obj (p:wait)]
    (str.trim (. obj :stdout))))

(defn open [lines]
  (let [buf (vim.api.nvim_create_buf false true)]
    (nvim.buf_set_text buf 0 0 0 0 lines)
    [(open-win buf {}) buf]))

(defn open-new-buffer [s]
  (let [buf (vim.api.nvim_create_buf true false)]
    (vim.api.nvim_win_set_buf 0 buf)
    ;; TODO this call fails during autocmd but it partially works enough
    ;; that the buffer has the right name
    (pcall (fn [] (vim.api.nvim_buf_set_name buf s)))
    (vim.api.nvim_command "set filetype=markdown")
    buf))

(comment
  (open-new-buffer "runbook-docker.md"))

;; have a global flag for whether we're following the "chat" buffer
(var follow? true)

(defn toggleFollow []
  (set follow? (not follow?)))

(nvim.set_keymap :n :<leader>pt ":lua require('slim.nvim').toggleFollow()<CR>" {})

(defn start-streaming [stream-generator]
  "starts a stream of messages into a new buffer"
  (var tokens [])
  (var append true)
  (let [buf (open-new-buffer "chat")]
    (let [t (show-spinner buf 1) ]
      (nvim.buf_set_lines buf -1 -1 false ["" ""])
      (stream-generator
        ;; messages callback
        (fn [s]
          (vim.schedule
            (fn []
              (t:stop)
              (set tokens (core.concat tokens [s]))
              ;; reset everything
              (vim.api.nvim_buf_set_lines buf 1 -1 false (str.split (str.join tokens) "\n"))
              (when follow?
                (vim.cmd ":$"))
              (set append true))))
        ;; functions callback - not appending - updating a json doc
        (fn [s]
          ;; TODO work differently for messages versus functions
          ;; functions update the last token
          ;; messages are appended
          (vim.schedule
            (fn []
              (t:stop)
              (if append
                (set tokens (core.concat tokens [s]))
                (set tokens (core.concat (core.butlast tokens) [s])))
              ;; reset everything
              (vim.api.nvim_buf_set_lines buf 1 -1 false (str.split (str.join tokens) "\n"))
              (when follow?
                (vim.cmd ":$"))
              (set append false))))))))

(defn stream-into-buffer [stream-generator prompt]
  (var tokens [])
  (let [lines (str.split prompt "\n")
        [win buf] (open lines)]
    (let [t (show-spinner buf (core.inc (core.count lines))) ]
      (nvim.buf_set_lines buf -1 -1 false ["" ""])
      (stream-generator
        prompt
        (fn [s]
          (vim.schedule
            (fn []
              (t:stop)
              (set tokens (core.concat tokens [s]))
              (vim.api.nvim_buf_set_lines buf (core.inc (core.count lines)) -1 false (str.split (str.join tokens) "\n")))))))))

(defn stream-into-empty-buffer [stream-generator prompt buffer-name]
  (var tokens [])
  (let [buf (open-new-buffer buffer-name)]
    (nvim.buf_set_lines buf -1 -1 false ["" ""])
    (stream-generator
       prompt
       (fn [s]
         (set tokens (core.concat tokens [s]))
         (let [lines (str.split (str.join tokens) "\n")]
           (vim.schedule
             (fn []
               (vim.api.nvim_buf_set_lines
                   buf
                   0 -1 false lines))))))))

(defn open-file [path]
  (let [win (vim.api.nvim_tabpage_get_win 0)]
    (vim.cmd "vsplit")
    (vim.cmd (.. "e " path))
    (let [buf (vim.api.nvim_get_current_buf)]
      (vim.api.nvim_set_current_win win)
      buf)))

(defn append [buf lines]
  (vim.api.nvim_buf_set_lines
    buf
    (core.count
      (vim.api.nvim_buf_get_lines buf 0 -1 false))
    -1
    false
    lines))

(comment
  ;; test open and append
  (def buf (open-file "Dockerfile.test"))
  (append buf ["yo"])
  (let [buf (nvim.create_buf false true)]
    (open-win buf {:title "hey"})
    (show-spinner buf)))
