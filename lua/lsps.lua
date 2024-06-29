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
local cmplsp, core, fs, keymaps, nvim, sha2, str = autoload("cmp_nvim_lsp"), autoload("aniseed.core"), autoload("aniseed.fs"), autoload("keymaps"), autoload("aniseed.nvim"), autoload("sha2"), autoload("aniseed.string")
do end (_2amodule_locals_2a)["cmplsp"] = cmplsp
_2amodule_locals_2a["core"] = core
_2amodule_locals_2a["fs"] = fs
_2amodule_locals_2a["keymaps"] = keymaps
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["sha2"] = sha2
_2amodule_locals_2a["str"] = str
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
local function last_2(v)
  local c = #v
  local n
  if (c >= 2) then
    n = (c - 1)
  else
    n = 1
  end
  local tbl_17_auto = {}
  local i_18_auto = #tbl_17_auto
  for i = n, c do
    local val_19_auto = v[i]
    if (nil ~= val_19_auto) then
      i_18_auto = (i_18_auto + 1)
      do end (tbl_17_auto)[i_18_auto] = val_19_auto
    else
    end
  end
  return tbl_17_auto
end
_2amodule_2a["last-2"] = last_2
local function last_n_segments(s, separator)
  return str.join(separator, last_2(str.split(s, separator)))
end
_2amodule_2a["last-n-segments"] = last_n_segments
local function block_map(m)
  local function _8_(agg, _6_)
    local _arg_7_ = _6_
    local uri = _arg_7_[1]
    local blocks = _arg_7_[2]
    local function _11_(m0, _9_)
      local _arg_10_ = _9_
      local command = _arg_10_["command"]
      local script = _arg_10_["script"]
      return core.assoc(m0, string.format("%-30s (%s)", command, last_n_segments(uri, "/")), script)
    end
    return core.reduce(_11_, agg, blocks)
  end
  return core.reduce(_8_, {}, core["kv-pairs"](m))
end
_2amodule_2a["block-map"] = block_map
local function runInTerminal()
  local blocks_in_scope = block_map(commands)
  local function _12_(command, _)
    if command then
      return run_in_terminal(blocks_in_scope[command])
    else
      return nil
    end
  end
  return vim.ui.select(core.keys(blocks_in_scope), {prompt = "Select a command:"}, _12_)
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
local function notify(channel, data)
  local _15_ = get_client_by_name("docker_lsp")
  if (nil ~= _15_) then
    local lsp = _15_
    return lsp.notify(channel, data)
  elseif true then
    local _ = _15_
    return core.println(channel, data)
  else
    return nil
  end
end
_2amodule_2a["notify"] = notify
local function cli_helper_handler(err, result, ctx, config)
  local p
  local function _17_(err0, data)
    return notify("$/docker/cli-helper", {stdout = data, id = result.id})
  end
  local function _18_(err0, data)
    return notify("$/docker/cli-helper", {stderr = data, id = result.id})
  end
  local function _21_(_19_)
    local _arg_20_ = _19_
    local code = _arg_20_["code"]
    local signal = _arg_20_["signal"]
    local data = _arg_20_
    local function _22_()
      if code then
        return {exit = code}
      else
        return nil
      end
    end
    local function _23_()
      if signal then
        return {signal = signal}
      else
        return nil
      end
    end
    return notify("$/docker/cli-helper", core.assoc(core.merge(core.merge({}, _22_()), _23_()), "id", result.id))
  end
  p = vim.system(core.concat({result.executable}, result.args), {text = true, stdout = _17_, stderr = _18_, stdin = false}, _21_)
  return {pid = p.pid}
end
_2amodule_2a["cli-helper-handler"] = cli_helper_handler
local function terminal_bind_handler(err, result, ctx, config)
  if err then
    core.println("terminal-bind err: ", err)
  else
  end
  local id = register_content(result.content)
  return vim.api.nvim_set_keymap("n", ("<leader>" .. vim.fn.input("Please enter a binding: ")), (":lua require('lsps').runInTerminal( '" .. id .. "' )<CR>"), {})
end
_2amodule_2a["terminal-bind-handler"] = terminal_bind_handler
local function inlay_hint_refresh_handler(err, result, ctx, config)
  core.println("inlay-hint-refresh-handler", ctx)
  local r = vim.lsp.inlay_hint.on_refresh(err, result, ctx, config)
  core.println("inlay-hint-refresh-handler complete")
  return r
end
_2amodule_2a["inlay-hint-refresh-handler"] = inlay_hint_refresh_handler
local function terminal_registration_handler(err, result, ctx, config)
  local _let_25_ = result
  local blocks = _let_25_["blocks"]
  local uri = _let_25_["uri"]
  local function _26_(agg, m)
    core.assoc(agg, m.command, m.script)
    return {}
  end
  commands = core.assoc(commands, uri, core.reduce(_26_, blocks))
  return nil
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
local function list()
  local function _28_(client)
    return client.name
  end
  return core.map(_28_, vim.lsp.get_clients())
end
_2amodule_2a["list"] = list
local handlers = {["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {severity_sort = true, underline = true, update_in_insert = false, virtual_text = false}), ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {border = "single"}), ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {border = "single"}), ["textDocument/codeLens"] = vim.lsp.with(vim.lsp.codelens.on_codelens, {border = "single"})}
_2amodule_2a["handlers"] = handlers
local function docker_lsp_nix_runner(root_dir)
  return {"nix", "run", "--quiet", "--log-format", "raw", "/Users/slim/docker/lsp/#clj", "--", "--pod-exe-path", "/Users/slim/docker/babashka-pod-docker/result/bin/entrypoint", "--profile", "all"}
end
_2amodule_2a["docker-lsp-nix-runner"] = docker_lsp_nix_runner
local function docker_lsp_clj_runner(root_dir)
  return {"bash", "-c", "cd ~/docker/lsp && eval \"$(direnv export bash)\" && clojure -A:start --pod-exe-path /Users/slim/docker/babashka-pod-docker/result/bin/entrypoint"}
end
_2amodule_2a["docker-lsp-clj-runner"] = docker_lsp_clj_runner
local function docker_lsp_docker_runner(root_dir)
  return {"docker", "run", "--name", core.str("nvim", core.rand()), "--rm", "--init", "--interactive", "--pull", "always", "-v", "/var/run/docker.sock:/var/run/docker.sock", "--mount", "type=volume,source=docker-lsp,target=/docker", "--mount", ("type=bind,source=" .. root_dir .. ",target=/project"), "--label", core.str("com.docker.lsp.workspace_roots=", root_dir), "--label", "com.docker.lsp=true", "--label", "com.docker.lsp.extension=labs-make-runbook", core.str("docker/lsp:", (os.getenv("DOCKER_LSP_TAG") or "latest")), "listen", "--workspace", "/docker", "--root-dir", root_dir, "--profile", "all"}
end
_2amodule_2a["docker-lsp-docker-runner"] = docker_lsp_docker_runner
local docker_lsp_filetypes = {"dockerfile", "dockerignore", "dockercompose.yaml", "markdown", "datalog-edn", "shellscript"}
_2amodule_2a["docker-lsp-filetypes"] = docker_lsp_filetypes
local attach_callback = nil
local function setup(cb)
  attach_callback = cb
  return nil
end
_2amodule_2a["setup"] = setup
local function start(root_dir, extra_handlers)
  local _29_
  if ("nix" == os.getenv("DOCKER_LSP")) then
    _29_ = docker_lsp_nix_runner(root_dir)
  elseif ("clj" == os.getenv("DOCKER_LSP")) then
    _29_ = docker_lsp_clj_runner(root_dir)
  else
    _29_ = docker_lsp_docker_runner(root_dir)
  end
  return vim.lsp.start({name = "docker_lsp", cmd = _29_, root_dir = root_dir, on_attach = (attach_callback or keymaps["default-attach-callback"]), settings = {docker = {assistant = {debug = true}, scout = {["language-gateway"] = "https://api.scout-stage.docker.com/v1/language-gateway"}}}, handlers = core.merge(handlers, extra_handlers)})
end
_2amodule_2a["start"] = start
local function attach_current_buffers()
  local bufs = vim.api.nvim_list_bufs()
  local function _31_(bufnr)
    core.println("attach ", bufnr)
    return vim.lsp.buf_attach_client(bufnr, (get_client_by_name("docker_lsp")).id)
  end
  return core.map(_31_, core.vals(bufs))
end
_2amodule_2a["attach-current-buffers"] = attach_current_buffers
vim.api.nvim_create_augroup("docker-ai", {})
local extra_handlers = {["docker/jwt"] = jwt_handler, ["$terminal/run"] = terminal_run_handler, ["$bind/run"] = terminal_bind_handler, ["$bind/register"] = terminal_registration_handler, ["docker/cli-helper"] = cli_helper_handler, ["workspace/inlayHint/refresh"] = inlay_hint_refresh_handler}
_2amodule_2a["extra-handlers"] = extra_handlers
local function _32_()
  local client = get_client_by_name("docker_lsp")
  if client then
    vim.lsp.buf_attach_client(0, client.id)
  else
    start(vim.fn.getcwd(), extra_handlers)
  end
  return false
end
vim.api.nvim_create_autocmd("FileType", {group = "docker-ai", pattern = docker_lsp_filetypes, callback = _32_, once = false})
return _2amodule_2a