local _2afile_2a = "fnl/lsps.fnl"
local _2amodule_name_2a = "lsps"
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
local cmplsp, core, nvim = autoload("cmp_nvim_lsp"), autoload("aniseed.core"), autoload("aniseed.nvim")
do end (_2amodule_locals_2a)["cmplsp"] = cmplsp
_2amodule_locals_2a["core"] = core
_2amodule_locals_2a["nvim"] = nvim
local capabilities = cmplsp.default_capabilities()
do end (_2amodule_2a)["capabilities"] = capabilities
local function get_client_by_name(s)
  local function _1_(client)
    if (client.name == s) then
      return client
    else
      return nil
    end
  end
  return core.some(_1_, vim.lsp.get_clients())
end
_2amodule_2a["get-client-by-name"] = get_client_by_name
local function list()
  local function _3_(client)
    return client.name
  end
  return core.map(_3_, vim.lsp.get_active_clients())
end
_2amodule_2a["list"] = list
local handlers = {["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {severity_sort = true, underline = true, virtual_text = false, update_in_insert = false}), ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {border = "single"}), ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {border = "single"}), ["textDocument/codeLens"] = vim.lsp.with(vim.lsp.codelens.on_codelens, {border = "single"})}
_2amodule_2a["handlers"] = handlers
local function attach_callback(client, bufnr)
  nvim.buf_set_keymap(bufnr, "n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>ld", "<Cmd>lua vim.lsp.buf.declaration()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lt", "<cmd>lua vim.lsp.buf.type_definition()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lh", "<cmd>lua vim.lsp.buf.signature_help()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>ln", "<cmd>lua vim.lsp.buf.rename()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>le", "<cmd>lua vim.diagnostic.open_float()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>ll", "<cmd>lua vim.diagnostic.setloclist()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lf", "<cmd>lua vim.lsp.buf.format()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "v", "<leader>lf", "<cmd>lua vim.lsp.buf.format()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lj", "<cmd>lua vim.diagnostic.goto_next()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lk", "<cmd>lua vim.diagnostic.goto_prev()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "v", "<leader>la", "<cmd>lua vim.lsp.buf.range_code_action()<CR> ", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<cmd>.", "<cmd>lua vim.lsp.buf.range_code_action()<CR> ", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<alt>.", "<cmd>lua vim.lsp.buf.range_code_action()<CR> ", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lcld", "<cmd>lua vim.lsp.codelens.refresh()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lclr", "<cmd>lua vim.lsp.codelens.run()<CR>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lw", ":lua require('telescope.builtin').diagnostics()<cr>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>lr", ":lua require('telescope.builtin').lsp_references()<cr>", {noremap = true})
  nvim.buf_set_keymap(bufnr, "n", "<leader>li", ":lua require('telescope.builtin').lsp_implementations()<cr>", {noremap = true})
  return nvim.buf_set_keymap(bufnr, "n", "<leader>lx", ":lua require('config.custom').tail_server_info()<cr>", {noremap = true})
end
_2amodule_2a["attach-callback"] = attach_callback
local function docker_lsp_nix_runner(root_dir)
  return {"nix", "run", "/Users/slim/docker/lsp/#clj", "--", "--pod-exe-path", "/Users/slim/.docker/cli-plugins/docker-pod"}
end
_2amodule_2a["docker-lsp-nix-runner"] = docker_lsp_nix_runner
local function docker_lsp_docker_runner(root_dir)
  return {"docker", "run", "--rm", "--init", "--interactive", "--mount", "type=volume,source=docker-lsp,target=/docker", "--mount", ("type=bind,source=" .. root_dir .. ",target=/project"), "vonwig/lsp", "listen", "--workspace", "/docker", "--root-dir", root_dir}
end
_2amodule_2a["docker-lsp-docker-runner"] = docker_lsp_docker_runner
local docker_lsp_filetypes = {"dockerfile", "dockerignore", "dockercompose", "markdown", "datalog-edn", "shellscript"}
_2amodule_2a["docker-lsp-filetypes"] = docker_lsp_filetypes
local function start(root_dir, extra_handlers)
  return vim.lsp.start({name = "docker_lsp", cmd = docker_lsp_nix_runner(root_dir), cmd_env = {DOCKER_LSP = "nix"}, root_dir = root_dir, on_attach = attach_callback, settings = {docker = {assistant = {debug = true}}}, handlers = core.merge(handlers, extra_handlers)})
end
_2amodule_2a["start"] = start
vim.api.nvim_create_augroup("docker-ai", {})
local function _4_()
  local client = get_client_by_name("docker_lsp")
  if client then
    core.println("attach docker_lsp to current buffer")
    vim.lsp.buf_attach_client(0, client.id)
  else
  end
  return false
end
vim.api.nvim_create_autocmd("FileType", {group = "docker-ai", pattern = docker_lsp_filetypes, callback = _4_, once = false})
return _2amodule_2a