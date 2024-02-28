(module lsps
  {autoload {cmplsp cmp_nvim_lsp
             core aniseed.core
             nvim aniseed.nvim
             keymaps keymaps
             sha2 sha2 }})

;; jwt handler
(defn jwt []
  (let [p (vim.system 
            ["docker-credential-desktop" "get"] 
            {:text true :stdin "https://index.docker.io/v1//access-token"})
        obj (p:wait)]
    (. (vim.json.decode (. obj :stdout)) :Secret)))

(defn use-bash [s]
  ;;(.. "bash --init-file <(echo '" s "')")
  s)

(defn run-in-terminal [s]
  (let [current-win (nvim.tabpage_get_win 0)
        original-buf (nvim.win_get_buf current-win)
        term-buf (nvim.create_buf false true)]
    (vim.cmd "split")
    (let [new-win (nvim.tabpage_get_win 0)]
      (nvim.win_set_buf new-win term-buf)
      (nvim.fn.termopen (use-bash s)))))

(var commands {})

(defn register-content [s]
  (let [code (vim.fn.sha256 s)]
    (set commands (core.assoc commands code s))
    code))

(defn runInTerminal []
  (vim.ui.select
    (core.keys commands)
    {:prompt "Select a command:"}
    (fn [command _]
      (when command
        (run-in-terminal (. commands command))))))

; lsp $terminal/run request handler
(defn terminal-run-handler [err result ctx config]
  "handler for lsps that request some content"
  (if err
    (core.println "terminal-run err: " err))
  (core.println "terminal-run" result)
  (run-in-terminal (. result :content)))

(defn terminal-bind-handler [err result ctx config]
  "handler for lsps that request some content"
  (if err
    (core.println "terminal-bind err: " err))
  (let [id (register-content (. result :content))]
    (vim.api.nvim_set_keymap :n (.. "<leader>" (vim.fn.input "Please enter a binding: ")) (.. ":lua require('lsps').runInTerminal( '" id "' )<CR>") {})))

(defn terminal-registration-handler [err result ctx config]
  (core.println "terminal-registration-handler " result)
  (set commands {})
  (->> (. result :blocks)
       (core.map (fn [m] 
                   (set commands 
                     (core.assoc commands (. m :command) (. m :script)))))))

(vim.api.nvim_set_keymap :n  ",run" (.. ":lua require('lsps').runInTerminal()<CR>") {})

; docker ai lsp docker/jwt request handler (both lsps)
(defn jwt-handler [err result ctx config]
  "handler for lsps that need a jwt"
  (if err
    (core.println "jwt err: " err))
  (jwt))

(def capabilities (cmplsp.default_capabilities))

(defn get-client-by-name [s] 
  (core.some 
    (fn [client] (when (= client.name s) client)) (vim.lsp.get_clients)))

(defn list []
  (core.map (fn [client] (. client :name)) (vim.lsp.get_active_clients)))

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
   "/Users/slim/docker/lsp/#clj"
   "--"
   "--pod-exe-path" "/Users/slim/.docker/cli-plugins/docker-pod"])

(defn docker-lsp-docker-runner [root-dir]
  ["docker" "run"
   "--rm" "--init" "--interactive"
   "--mount" "type=volume,source=docker-lsp,target=/docker"
   "--mount" (.. "type=bind,source=" root-dir ",target=/project")
   "docker/lsp:staging"
   "listen"
   "--pod-exe-path" "/app/result/bin/babashka-pod-docker"
   "--workspace" "/docker"
   "--root-dir" root-dir])

(def docker-lsp-filetypes ["dockerfile" "dockerignore" "dockercompose" "markdown" "datalog-edn" "shellscript"])

(var attach-callback nil)

(defn setup [cb]
  "setup the lsp attach callback"
  (set attach-callback cb))

;; vim.lsp.start attaches the current buffer
(defn start [root-dir extra-handlers]
  (vim.lsp.start {:name "docker_lsp"
                  :cmd (if (= "nix" (os.getenv "DOCKER_LSP"))
                         (docker-lsp-nix-runner root-dir)
                         (docker-lsp-docker-runner root-dir))
                  :root_dir root-dir
                  :on_attach (or attach-callback keymaps.default-attach-callback)
                  :settings 
                  {:docker
                   {:assistant
                    {:debug true}}}
                  :handlers (core.merge
                              handlers
                              extra-handlers)}))

(defn start-dockerai-lsp 
  [root-dir 
   extra-handlers
   prompt-handler
   exit-handler]
  (vim.lsp.start {:name "docker_ai"
                  :cmd ["docker" "run"
                        "--rm" "--init" "--interactive"
                        "docker/labs-assistant-ml:staging"]
                  :root_dir root-dir
                  :handlers (core.merge
                              {"$/prompt" prompt-handler
                               "$/exit" exit-handler}
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
                        (start 
                          (vim.fn.getcwd)
                          {"docker/jwt" jwt-handler
                           "$terminal/run" terminal-run-handler
                           "$bind/run" terminal-bind-handler
                           "$bind/register" terminal-registration-handler}))
                      ;; don't delete the autocmd
                      false))})

