(module lsps
  {autoload {cmplsp cmp_nvim_lsp
             core aniseed.core
             nvim aniseed.nvim}})

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

(defn attach-callback [client bufnr]
  (do
    (nvim.buf_set_keymap bufnr :n :gd "<Cmd>lua vim.lsp.buf.definition()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :K "<Cmd>lua vim.lsp.buf.hover()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>ld "<Cmd>lua vim.lsp.buf.declaration()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>lt "<cmd>lua vim.lsp.buf.type_definition()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>lh "<cmd>lua vim.lsp.buf.signature_help()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>ln "<cmd>lua vim.lsp.buf.rename()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>le "<cmd>lua vim.diagnostic.open_float()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>ll "<cmd>lua vim.diagnostic.setloclist()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>lf "<cmd>lua vim.lsp.buf.format()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :v :<leader>lf "<cmd>lua vim.lsp.buf.format()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>lj "<cmd>lua vim.diagnostic.goto_next()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>lk "<cmd>lua vim.diagnostic.goto_prev()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>la "<cmd>lua vim.lsp.buf.code_action()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :v :<leader>la "<cmd>lua vim.lsp.buf.range_code_action()<CR> " {:noremap true})
    (nvim.buf_set_keymap bufnr :n "<cmd>." "<cmd>lua vim.lsp.buf.range_code_action()<CR> " {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<alt>. "<cmd>lua vim.lsp.buf.range_code_action()<CR> " {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>lcld "<cmd>lua vim.lsp.codelens.refresh()<CR>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>lclr "<cmd>lua vim.lsp.codelens.run()<CR>" {:noremap true})
    ;telescope
    (nvim.buf_set_keymap bufnr :n :<leader>lw ":lua require('telescope.builtin').diagnostics()<cr>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>lr ":lua require('telescope.builtin').lsp_references()<cr>" {:noremap true})
    (nvim.buf_set_keymap bufnr :n :<leader>li ":lua require('telescope.builtin').lsp_implementations()<cr>" {:noremap true})
    ;; start tailing lsp log
    (nvim.buf_set_keymap bufnr :n :<leader>lx ":lua require('config.custom').tail_server_info()<cr>" {:noremap true})
    ))

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
   "vonwig/lsp"
   "listen"
   "--workspace" "/docker"
   "--root-dir" root-dir])

  ;; docker-lsp
  ;; ["java" "-jar" "/Users/slim/atmhq/lsp/target/docker-lsp-0.0.1-standalone.jar"]
  ;; ["docker" "run" "--rm" "--init" "-i" "-v" "/tmp:/tmp" "atomist/lsp"]
  ;(lsp.docker_lsp.setup {:cmd ["will-override-below"]
                         ;:on_new_config (fn [new-config new-root-dir] 
                                          ;(tset
                                            ;new-config 
                                            ;:cmd 
                                            ;(if (not (os.getenv "USE_DOCKER"))
                                              ;(docker-lsp-nix-runner new-root-dir)
                                              ;(docker-lsp-docker-runner new-root-dir))))
                         ;:on_attach on_attach
                         ;:handlers (core.assoc handlers "docker/jwt" dockerai.jwt-handler)
                         ;:capabilities capabilities})

(def docker-lsp-filetypes ["dockerfile" "dockerignore" "dockercompose" "markdown" "datalog-edn" "shellscript"])

;; vim.lsp.start attaches the current buffer
(defn start [root-dir extra-handlers]
  (vim.lsp.start {:name "docker_lsp"
                  :cmd (docker-lsp-nix-runner root-dir)
                  :cmd_env {"DOCKER_LSP" "nix"}
                  :root_dir root-dir
                  :on_attach attach-callback
                  :settings 
                  {:docker
                   {:assistant
                    {:debug true}}}
                  :handlers (core.merge
                              handlers
                              extra-handlers)}))

(vim.api.nvim_create_augroup
  "docker-ai" {})

(vim.api.nvim_create_autocmd
  "FileType"
  {:group "docker-ai"
   :pattern docker-lsp-filetypes
   :once false
   :callback (fn [] (let [client (get-client-by-name "docker_lsp")]
                      (when client
                        (core.println "attach docker_lsp to current buffer")
                        (vim.lsp.buf_attach_client 0 client.id))
                      ;; don't delete the autocmd
                      false))})

