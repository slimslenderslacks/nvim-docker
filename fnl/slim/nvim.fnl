(module slim.nvim
  {autoload {nvim aniseed.nvim
             core aniseed.core
             str aniseed.string
             lspconfig-util lspconfig.util}})

(defn git-root []
  (or
    ((lspconfig-util.root_pattern ".git") (vim.fn.getcwd))
    (vim.fn.getcwd)))

(defn get-current-buffer-selection []
  (let [[_ s1 e1 _] (nvim.fn.getpos "'<")
        [_ s2 e2 _] (nvim.fn.getpos "'>")]
    (nvim.buf_get_text (nvim.buf.nr) (- s1 1) (- e1 1) (- s2 1) (- e2 1) {})))

(def win-opts 
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
  (let [win (nvim.open_win buf true (core.merge win-opts opts))]
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
    [(open-win buf {:title "Copilot"}) buf]))

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
