(module lsps
  {autoload {cmplsp cmp_nvim_lsp
             core aniseed.core
             fs aniseed.fs
             nvim aniseed.nvim
             str aniseed.string
             keymaps keymaps
             sha2 sha2}})

(var lsp-client-id nil)

(defn get-client-by-name [s]
  (if lsp-client-id
    (vim.lsp.get_client_by_id lsp-client-id)))

;; jwt handler
(defn jwt []
  (let [p (vim.system
            ["docker-credential-desktop" "get"]
            {:text true :stdin "https://index.docker.io/v1//access-token"})
        obj (p:wait)]
    (if (= (. obj :code) 0)
      (. (vim.json.decode (. obj :stdout)) :Secret)
      {:code 400 :message "no docker-credential-desktop in PATH or " :data {:code (. obj :code)}})))

(defn use-bash [pwd s]
  ;;(.. "bash --init-file <(echo '" s "')")
  (.. "cd " pwd " && " s))

(defn run-in-terminal [pwd s]
  "pwd - absolute path of working directory to run script
   s - the script to run"
  (let [current-win (nvim.tabpage_get_win 0)
        original-buf (nvim.win_get_buf current-win)
        term-buf (nvim.create_buf false true)]
    (vim.cmd "split")
    (let [new-win (nvim.tabpage_get_win 0)]
      (nvim.win_set_buf new-win term-buf)
      (nvim.fn.termopen (use-bash pwd s)))))

(var commands {})

(defn register-content [s]
  (let [code (vim.fn.sha256 s)]
    (set commands (core.assoc commands code s))
    code))

(defn last-2 [v]
  (let [c (length v)
        n (if (>= c 2)
            (- c 1)
            1)]
    (fcollect [i n c]
              (. v i))))

(defn last-n-segments [s separator]
  (->> (str.split s separator)
       (last-2)
       (str.join separator)))

(defn uri-basedir [uri]
  (nvim.fn.fnamemodify (vim.fn.substitute uri "file://" "" "") ":h"))

(comment
  (uri-basedir "file:///Users/slim"))

;; TODO store both the script and basedir of the script so we can run the script in the pwd
(defn block-map [m]
  (core.reduce
    (fn [agg [uri blocks]]
      (core.reduce
        (fn [m {:command command :script script}]
          (core.assoc m (string.format "%-30s (%s)" command (last-n-segments uri "/")) {:basedir (uri-basedir uri) :script script}))
        agg
        blocks))
    {}
    (core.kv-pairs m)))

(defn runInTerminal []
  (let [blocks-in-scope (block-map commands)]
    (vim.ui.select
      (core.keys blocks-in-scope)
      {:prompt "Select a command:"}
      (fn [command _]
        (when command
          (run-in-terminal (. blocks-in-scope command :basedir) (. blocks-in-scope command :script)))))))

; lsp $terminal/run request handler
(defn terminal-run-handler [err result ctx config]
  "handler for lsps that request some content"
  (if err
    (core.println "terminal-run err: " err))
  (core.println "terminal-run" result)
  (run-in-terminal (uri-basedir (. result :uri)) (. result :content)))

(defn notify [channel data]
  (case (get-client-by-name "docker_lsp")
    lsp (lsp.notify channel data)
    _ (core.println channel data)))

(defn cli-helper-handler [err result ctx config]
  "handler for lsps that request some content"
  ;; for request handlers, the result is the params
  ;; the ctx has the client_id and the method
  ;; the config is probably empty
  (let [p (vim.system
            (core.concat [(. result :executable)] (. result :args))
            {:text true
             :stdin false
             :stdout (fn [err data]
                       (notify "$/docker/cli-helper" {:stdout data :id (. result :id)}))
             :stderr (fn [err data]
                       (notify "$/docker/cli-helper" {:stderr data :id (. result :id)}))}
            (fn [{:code code :signal signal &as data}]
              (notify "$/docker/cli-helper" (-> {}
                                                (core.merge (if code {:exit code}))
                                                (core.merge (if signal {:signal signal}))
                                                (core.assoc :id (. result :id))))))]
    {:pid (. p :pid)}))

;(cli-helper-handler nil {:executable "docker" :args ["ps"]} nil nil)

(defn terminal-bind-handler [err result ctx config]
  "handler for lsps that request some content"
  (if err
    (core.println "terminal-bind err: " err))
  (let [id (register-content (. result :content))]
    (vim.api.nvim_set_keymap :n (.. "<leader>" (vim.fn.input "Please enter a binding: ")) (.. ":lua require('lsps').runInTerminal( '" id "' )<CR>") {})))

(defn inlay-hint-refresh-handler [err result ctx config]
  (core.println "inlay-hint-refresh-handler" ctx)
  (let [r (vim.lsp.inlay_hint.on_refresh err result ctx config)]
    (core.println "inlay-hint-refresh-handler complete")
    ; TODO hack - how do we force redraw of current buffer?  edit buffer does it but ...
    r))

;; re-registers docker:command blocks when a uri is updated
;; notification will be a map with two keys (:uri and :blocks)
(defn terminal-registration-handler [err result ctx config]
  (let [{:blocks blocks :uri uri} result]
    (set commands
         (core.assoc commands uri
                     (->> blocks
                          (core.reduce
                            (fn [agg m]
                              (core.assoc agg (. m :command) (. m :script))
                              {})))))))

(vim.api.nvim_set_keymap :n  ",run" (.. ":lua require('lsps').runInTerminal()<CR>") {})

; docker ai lsp docker/jwt request handler (both lsps)
(defn jwt-handler [err result ctx config]
  "handler for lsps that need a jwt"
  (let [(ok? val-or-msg) (pcall jwt)]
    (if ok?
      val-or-msg
      {:code -32603 :message val-or-msg})))

(def capabilities (cmplsp.default_capabilities))

(defn list []
  (core.map (fn [client] (. client :name)) (vim.lsp.get_clients)))

(def handlers
  {"textDocument/publishDiagnostics"
    (vim.lsp.with
      vim.lsp.diagnostic.on_publish_diagnostics
      {:severity_sort true
       :update_in_insert false
       :underline true
       :virtual_text false})
    "textDocument/hover"
    (vim.lsp.with
      vim.lsp.handlers.hover
      {:border "single"})
    "textDocument/signatureHelp"
    (vim.lsp.with
      vim.lsp.handlers.signature_help
      {:border "single"})
    "textDocument/codeLens"
    (vim.lsp.with
      vim.lsp.codelens.on_codelens
      {:border "single"})})

(defn docker-lsp-nix-runner [root-dir]
  ["nix"
   "run"
   "--quiet"
   "--log-format"
   "raw"
   "/Users/slim/docker/lsp/#clj"
   "--"
   "--pod-exe-path" "/Users/slim/docker/babashka-pod-docker/result/bin/entrypoint"
   "--profile" "all"])

(defn docker-lsp-clj-runner [root-dir]
  ["bash"
   "-c"
   "cd ~/docker/lsp && eval \"$(direnv export bash)\" && clojure -A:start --pod-exe-path /Users/slim/docker/babashka-pod-docker/result/bin/entrypoint"])

(defn docker-lsp-docker-runner [root-dir]
  ["docker" "run"
   "--name" (core.str "nvim" (core.rand))
   "--rm" "--init" "--interactive"
   ;;"--pull" "always"
   "-v" "/var/run/docker.sock:/var/run/docker.sock"
   "--mount" "type=volume,source=docker-lsp,target=/docker"
   "--mount" (.. "type=bind,source=" root-dir ",target=/project")
   "--label" (core.str "com.docker.lsp.workspace_roots=" root-dir)
   "--label" "com.docker.lsp=true"
   "--label" "com.docker.lsp.extension=labs-make-runbook"
   (core.str "docker/lsp:" (or (os.getenv "DOCKER_LSP_TAG") "latest"))
   "listen"
   "--workspace" "/docker"
   "--root-dir" root-dir
   "--profile" "all"])

(def docker-lsp-filetypes ["dockerfile" "dockerignore" "dockercompose.yaml" "markdown" "datalog-edn" "shellscript"])

(var attach-callback nil)

(defn setup [cb]
  "setup the lsp attach callback"
  (set attach-callback cb))

;; vim.lsp.start attaches the current buffer
(defn start [root-dir extra-handlers]
  (vim.lsp.start {:name "docker_lsp"
                  :cmd (if
                         (= "nix" (os.getenv "DOCKER_LSP"))
                         (docker-lsp-nix-runner root-dir)
                         (= "clj" (os.getenv "DOCKER_LSP"))
                         (docker-lsp-clj-runner root-dir)
                         (docker-lsp-docker-runner root-dir))
                  :root_dir root-dir
                  :on_attach (or attach-callback keymaps.default-attach-callback)
                  :settings
                  {:docker
                   {:assistant
                    {:debug true}
                    :scout
                    {:language-gateway "https://api.scout-stage.docker.com/v1/language-gateway"}}}
                  :handlers (core.merge
                              handlers
                              extra-handlers)}))

;; TODO not using this right now - important only if we're lazily starting the lsp with
;; open buffers
(defn attach-current-buffers []
  (let [bufs (vim.api.nvim_list_bufs)]
    (->> (core.vals bufs)
         ;(core.filter
           ;(fn [bufnr]
             ;(let [ft (. (. vim.bo bufnr) :filetype)]
               ;(core.println "check " bufnr ft)
               ;(core.some #(= ft $1) docker-lsp-filetypes))))
         (core.map (fn [bufnr]
                     (core.println "attach " bufnr)
                     (vim.lsp.buf_attach_client bufnr (. (get-client-by-name "docker_lsp") :id)))))))

(vim.api.nvim_create_augroup
  "docker-ai" {})

(def extra-handlers
  {"docker/jwt" jwt-handler
   "$terminal/run" terminal-run-handler
   "$bind/run" terminal-bind-handler
   "$bind/register" terminal-registration-handler
   "docker/cli-helper" cli-helper-handler
   "workspace/inlayHint/refresh" inlay-hint-refresh-handler})

;; once this module is required, the docker_lsp will
;; be attached to these buffers whenever opened
(vim.api.nvim_create_autocmd
  "FileType"
  {:group "docker-ai"
   :pattern docker-lsp-filetypes
   :once false
   :callback (fn [] (let [client (get-client-by-name "docker_lsp")]
                      (if client
                        (vim.lsp.buf_attach_client 0 client.id)
                        (set lsp-client-id
                          (start
                            (vim.fn.getcwd)
                            extra-handlers)))
                      ;; don't delete the autocmd
                      false))})

