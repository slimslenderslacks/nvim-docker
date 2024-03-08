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
local cmplsp, core, keymaps, nvim, sha2 = autoload("cmp_nvim_lsp"), autoload("aniseed.core"), autoload("keymaps"), autoload("aniseed.nvim"), autoload("sha2")
do end (_2amodule_locals_2a)["cmplsp"] = cmplsp
_2amodule_locals_2a["core"] = core
_2amodule_locals_2a["keymaps"] = keymaps
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["sha2"] = sha2
local function jwt()
  local p = vim.system({"docker-credential-desktop", "get"}, {text = true, stdin = "https://index.docker.io/v1//access-token"})
  local obj = p:wait()
  if (obj.code == 0) then
    return vim.json.decode(obj.stdout).Secret
  else
    return {code = 400, message = "no docker-credential-desktop in PATH or ", data = {code = obj.code}}
  end
end
_2amodule_2a["jwt"] = jwt
local function use_bash(s)
  return s
end
_2amodule_2a["use-bash"] = use_bash
local function run_in_terminal(s)
  local current_win = nvim.tabpage_get_win(0)
  local original_buf = nvim.win_get_buf(current_win)
  local term_buf = nvim.create_buf(false, true)
  vim.cmd("split")
  local new_win = nvim.tabpage_get_win(0)
  nvim.win_set_buf(new_win, term_buf)
  return nvim.fn.termopen(use_bash(s))
end
_2amodule_2a["run-in-terminal"] = run_in_terminal
local commands = {}
local function register_content(s)
  local code = vim.fn.sha256(s)
  commands = core.assoc(commands, code, s)
  return code
end
_2amodule_2a["register-content"] = register_content
local function runInTerminal()
  local function _2_(command, _)
    if command then
      return run_in_terminal(commands[command])
    else
      return nil
    end
  end
  return vim.ui.select(core.keys(commands), {prompt = "Select a command:"}, _2_)
end
_2amodule_2a["runInTerminal"] = runInTerminal
local function terminal_run_handler(err, result, ctx, config)
  if err then
    core.println("terminal-run err: ", err)
  else
  end
  core.println("terminal-run", result)
  return run_in_terminal(result.content)
end
_2amodule_2a["terminal-run-handler"] = terminal_run_handler
local function terminal_bind_handler(err, result, ctx, config)
  if err then
    core.println("terminal-bind err: ", err)
  else
  end
  local id = register_content(result.content)
  return vim.api.nvim_set_keymap("n", ("<leader>" .. vim.fn.input("Please enter a binding: ")), (":lua require('lsps').runInTerminal( '" .. id .. "' )<CR>"), {})
end
_2amodule_2a["terminal-bind-handler"] = terminal_bind_handler
local function terminal_registration_handler(err, result, ctx, config)
  core.println("terminal-registration-handler ", result)
  commands = {}
  local function _6_(m)
    commands = core.assoc(commands, m.command, m.script)
    return nil
  end
  return core.map(_6_, result.blocks)
end
_2amodule_2a["terminal-registration-handler"] = terminal_registration_handler
vim.api.nvim_set_keymap("n", ",run", ":lua require('lsps').runInTerminal()<CR>", {})
local function jwt_handler(err, result, ctx, config)
  local ok_3f, val_or_msg = pcall(jwt)
  if ok_3f then
    return val_or_msg
  else
    return {code = -32603, message = val_or_msg}
  end
end
_2amodule_2a["jwt-handler"] = jwt_handler
local capabilities = cmplsp.default_capabilities()
do end (_2amodule_2a)["capabilities"] = capabilities
local function get_client_by_name(s)
  local function _8_(client)
    if (client.name == s) then
      return client
    else
      return nil
    end
  end
  return core.some(_8_, vim.lsp.get_clients())
end
_2amodule_2a["get-client-by-name"] = get_client_by_name
local function list()
  local function _10_(client)
    return client.name
  end
  return core.map(_10_, vim.lsp.get_active_clients())
end
_2amodule_2a["list"] = list
local handlers = {["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {severity_sort = true, underline = true, update_in_insert = false, virtual_text = false}), ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {border = "single"}), ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {border = "single"}), ["textDocument/codeLens"] = vim.lsp.with(vim.lsp.codelens.on_codelens, {border = "single"})}
_2amodule_2a["handlers"] = handlers
local function docker_lsp_nix_runner(root_dir)
  return {"nix", "run", "--quiet", "--log-format", "raw", "/Users/slim/docker/lsp/#clj", "--", "--pod-exe-path", "/Users/slim/docker/babashka-pod-docker/result/bin/entrypoint"}
end
_2amodule_2a["docker-lsp-nix-runner"] = docker_lsp_nix_runner
local function docker_lsp_docker_runner(root_dir)
  return {"docker", "run", "--rm", "--init", "--interactive", "--mount", "type=volume,source=docker-lsp,target=/docker", "--mount", ("type=bind,source=" .. root_dir .. ",target=/project"), "docker/lsp:staging", "listen", "--pod-exe-path", "/app/result/bin/babashka-pod-docker", "--workspace", "/docker", "--root-dir", root_dir}
end
_2amodule_2a["docker-lsp-docker-runner"] = docker_lsp_docker_runner
local docker_lsp_filetypes = {"dockerfile", "dockerignore", "dockercompose", "markdown", "datalog-edn", "shellscript"}
_2amodule_2a["docker-lsp-filetypes"] = docker_lsp_filetypes
local attach_callback = nil
local function setup(cb)
  attach_callback = cb
  return nil
end
_2amodule_2a["setup"] = setup
local function start(root_dir, extra_handlers)
  local _11_
  if ("nix" == os.getenv("DOCKER_LSP")) then
    _11_ = docker_lsp_nix_runner(root_dir)
  else
    _11_ = docker_lsp_docker_runner(root_dir)
  end
  return vim.lsp.start({name = "docker_lsp", cmd = _11_, root_dir = root_dir, on_attach = (attach_callback or keymaps["default-attach-callback"]), settings = {docker = {assistant = {debug = true}}}, handlers = core.merge(handlers, extra_handlers)})
end
_2amodule_2a["start"] = start
local function start_dockerai_lsp(root_dir, extra_handlers, prompt_handler, exit_handler)
  return vim.lsp.start({name = "docker_ai", cmd = {"docker", "run", "--rm", "--init", "--interactive", "docker/labs-assistant-ml:staging"}, root_dir = root_dir, handlers = core.merge({["$/prompt"] = prompt_handler, ["$/exit"] = exit_handler}, extra_handlers)})
end
_2amodule_2a["start-dockerai-lsp"] = start_dockerai_lsp
local function attach_current_buffers()
  local bufs = vim.api.nvim_list_bufs()
  local function _13_(bufnr)
    core.println("attach ", bufnr)
    return vim.lsp.buf_attach_client(bufnr, (get_client_by_name("docker_lsp")).id)
  end
  return core.map(_13_, core.vals(bufs))
end
_2amodule_2a["attach-current-buffers"] = attach_current_buffers
vim.api.nvim_create_augroup("docker-ai", {})
local function _14_()
  local client = get_client_by_name("docker_lsp")
  if client then
    vim.lsp.buf_attach_client(0, client.id)
  else
    start(vim.fn.getcwd(), {["docker/jwt"] = jwt_handler, ["$terminal/run"] = terminal_run_handler, ["$bind/run"] = terminal_bind_handler, ["$bind/register"] = terminal_registration_handler})
  end
  return false
end
vim.api.nvim_create_autocmd("FileType", {group = "docker-ai", pattern = docker_lsp_filetypes, callback = _14_, once = false})
return _2amodule_2a