local _2afile_2a = "fnl/docker/setup.fnl"
local _2amodule_name_2a = "docker.setup"
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
local core, nvim, string, util, lsps = autoload("aniseed.core"), autoload("aniseed.nvim"), autoload("aniseed.string"), autoload("slim.nvim"), require("lsps")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["string"] = string
_2amodule_locals_2a["util"] = util
_2amodule_locals_2a["lsps"] = lsps
local function start_lsps()
  local root_dir = vim.fn.getcwd()
  return lsps.start(root_dir, lsps["extra-handlers"])
end
_2amodule_2a["start-lsps"] = start_lsps
local function stop()
  local docker_lsp = (lsps["get-client-by-name"]("docker_lsp")).id
  if docker_lsp then
    return vim.lsp.stop_client(docker_lsp, false)
  else
    return nil
  end
end
_2amodule_2a["stop"] = stop
local function lsp_debug(_)
  local function _2_(item)
    return item:gsub("_", " ")
  end
  local function _3_(selected, _0)
    local client = lsps["get-client-by-name"]("docker_lsp")
    return client.request_sync("docker/debug", {type = selected})
  end
  return vim.ui.select({"documents", "project-context", "tracking-data", "login", "alpine-packages", "repositories", "client-settings"}, {prompt = "Choose Type of Data:", format = _2_}, _3_)
end
_2amodule_2a["lsp-debug"] = lsp_debug
local function setup(_4_)
  local _arg_5_ = _4_
  local cb = _arg_5_["attach"]
  return lsps.setup(cb)
end
_2amodule_2a["setup"] = setup
local function tail_server_info()
  local clients = vim.lsp.get_active_clients()
  for n, client in pairs(clients) do
    if (client.name == "docker_lsp") then
      local result = client.request_sync("docker/serverInfo/raw", {}, 5000)
      print(result.result.port, result.result["log-path"], result.result["team-id"])
      nvim.command(core.str("vs | :term bash -c \"tail -f ", result.result["log-path"], "\""))
    else
    end
  end
  return nil
end
_2amodule_2a["tail_server_info"] = tail_server_info
local function set_scout_workspace(args)
  local clients = vim.lsp.get_active_clients()
  for n, client in pairs(clients) do
    if (client.name == "docker_lsp") then
      local result = client.request_sync("docker/select-scout-workspace", args, 5000)
      print(result)
    else
    end
  end
  return nil
end
_2amodule_2a["set_scout_workspace"] = set_scout_workspace
local function show_scout_workspace(args)
  local clients = vim.lsp.get_active_clients()
  for n, client in pairs(clients) do
    if (client.name == "docker_lsp") then
      local result = client.request_sync("docker/show-scout-workspace", args, 5000)
      print(result)
    else
    end
  end
  return nil
end
_2amodule_2a["show_scout_workspace"] = show_scout_workspace
local function docker_server_info(args)
  local clients = vim.lsp.get_active_clients()
  for n, client in pairs(clients) do
    if (client.name == "docker_lsp") then
      local result = client.request_sync("docker/serverInfo/show", args, 5000)
      core.println(result)
    else
    end
  end
  return nil
end
_2amodule_2a["docker_server_info"] = docker_server_info
local function docker_login(args)
  local clients = vim.lsp.get_active_clients()
  for n, client in pairs(clients) do
    if (client.name == "docker_lsp") then
      local logout_result = client.request_sync("docker/logout", args, 5000)
      local login_result = client.request_sync("docker/login", args, 5000)
      core.println(login_result)
    else
    end
  end
  return nil
end
_2amodule_2a["docker_login"] = docker_login
local function docker_logout(args)
  local clients = vim.lsp.get_active_clients()
  for n, client in pairs(clients) do
    if (client.name == "docker_lsp") then
      local result = client.request_sync("docker/logout", args, 5000)
      print(result)
    else
    end
  end
  return nil
end
_2amodule_2a["docker_logout"] = docker_logout
nvim.create_user_command("DockerServerInfo", docker_server_info, {nargs = "?"})
nvim.create_user_command("DockerDebug", lsp_debug, {desc = "Get some state from the Docker LSP"})
nvim.create_user_command("DockerShowOrg", show_scout_workspace, {nargs = "?"})
nvim.create_user_command("DockerSetOrg", show_scout_workspace, {nargs = "?"})
nvim.create_user_command("DockerLogin", docker_login, {nargs = "?"})
nvim.create_user_command("DockerLspStart", start_lsps, {desc = "Start the LSP without starting files"})
nvim.create_user_command("DockerLspStop", stop, {desc = "Stop the Docker LSP"})
--[[ (nvim.create_user_command "DockerLogout" docker_logout {:nargs "?"}) ]]
return _2amodule_2a