(module keymaps
  {autoload {nvim aniseed.nvim
             core aniseed.core}})

(defn default-attach-callback [client bufnr]
  (vim.lsp.inlay_hint.enable true {:bufnr bufnr})    

  (nvim.buf_set_keymap bufnr :n :gd           "<Cmd>lua vim.lsp.buf.definition()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :K            "<Cmd>lua vim.lsp.buf.hover()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>ld   "<Cmd>lua vim.lsp.buf.declaration()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>lt   "<cmd>lua vim.lsp.buf.type_definition()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>lh   "<cmd>lua vim.lsp.buf.signature_help()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>ln   "<cmd>lua vim.lsp.buf.rename()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>lf   "<cmd>lua vim.lsp.buf.format()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :v :<leader>lf   "<cmd>lua vim.lsp.buf.format()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>la   "<cmd>lua vim.lsp.buf.code_action()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :v :<leader>la   "<cmd>lua vim.lsp.buf.range_code_action()<CR> " {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>lcld "<cmd>lua vim.lsp.codelens.refresh()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>lclr "<cmd>lua vim.lsp.codelens.run()<CR>" {:noremap true})

  (nvim.buf_set_keymap bufnr :n :<leader>le   "<cmd>lua vim.diagnostic.open_float()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>ll   "<cmd>lua vim.diagnostic.setloclist()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>lj   "<cmd>lua vim.diagnostic.goto_next()<CR>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>lk   "<cmd>lua vim.diagnostic.goto_prev()<CR>" {:noremap true})

  ;; start tailing lsp log
  (nvim.buf_set_keymap bufnr :n :<leader>lx   ":lua require('config.custom').tail_server_info()<cr>" {:noremap true}) 

  ;; telescope - these should only be added if telescope has been added
  (nvim.buf_set_keymap bufnr :n :<leader>lw   ":lua require('telescope.builtin').diagnostics()<cr>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>lr   ":lua require('telescope.builtin').lsp_references()<cr>" {:noremap true})
  (nvim.buf_set_keymap bufnr :n :<leader>li   ":lua require('telescope.builtin').lsp_implementations()<cr>" {:noremap true}))
