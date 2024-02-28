local _2afile_2a = "fnl/keymaps.fnl"
local _2amodule_name_2a = "keymaps"
local _2amodule_2a
do
  package.loaded[_2amodule_name_2a] = {}
  _2amodule_2a = package.loaded[_2amodule_name_2a]
end
local _2amodule_locals_2a
do
  _2amodule_2a["aniseed/locals"] = {}
  _2amodule_locals_2a = (_2amodule_2a)["aniseed/locals"]
end
local autoload = (require("aniseed.autoload")).autoload
local nvim = autoload("aniseed.nvim")
do end (_2amodule_locals_2a)["nvim"] = nvim
local function default_attach_callback(client, bufnr)
  nvim.buf_set_keymap(bufnr, "n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>ld", "<Cmd>lua vim.lsp.buf.declaration()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lt", "<cmd>lua vim.lsp.buf.type_definition()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lh", "<cmd>lua vim.lsp.buf.signature_help()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>ln", "<cmd>lua vim.lsp.buf.rename()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lf", "<cmd>lua vim.lsp.buf.format()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "v", "<leader>lf", "<cmd>lua vim.lsp.buf.format()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "v", "<leader>la", "<cmd>lua vim.lsp.buf.range_code_action()<CR> ", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lcld", "<cmd>lua vim.lsp.codelens.refresh()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lclr", "<cmd>lua vim.lsp.codelens.run()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>le", "<cmd>lua vim.diagnostic.open_float()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>ll", "<cmd>lua vim.diagnostic.setloclist()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lj", "<cmd>lua vim.diagnostic.goto_next()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lk", "<cmd>lua vim.diagnostic.goto_prev()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lx", ":lua require('config.custom').tail_server_info()<cr>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lw", ":lua require('telescope.builtin').diagnostics()<cr>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lr", ":lua require('telescope.builtin').lsp_references()<cr>", {noremap = true})
  return nvim.buf_set_keymap(bufnr, "n", "<leader>li", ":lua require('telescope.builtin').lsp_implementations()<cr>", {noremap = true})
end
_2amodule_2a["default-attach-callback"] = default_attach_callback
return _2amodule_2a