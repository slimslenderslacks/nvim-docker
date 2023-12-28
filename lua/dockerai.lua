local _2afile_2a = "fnl/dockerai.fnl"
local _2amodule_name_2a = "dockerai"
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
local core, lsps, notebook, nvim, string, util = autoload("aniseed.core"), autoload("lsps"), autoload("notebook"), autoload("aniseed.nvim"), autoload("aniseed.string"), autoload("slim.nvim")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["lsps"] = lsps
_2amodule_locals_2a["notebook"] = notebook
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["string"] = string
_2amodule_locals_2a["util"] = util
vim.lsp.set_log_level("TRACE")
local use_nix_3f = true
_2amodule_2a["use-nix?"] = use_nix_3f
local function jwt()
  local p = vim.system({"docker-credential-desktop", "get"}, {text = true, stdin = "https://index.docker.io/v1//access-token"})
  local obj = p:wait()
  return vim.json.decode(obj.stdout).Secret
end
_2amodule_2a["jwt"] = jwt
local function decode_payload(s)
  return vim.json.decode(vim.base64.decode(((vim.split(s, ".", {plain = true}))[2] .. "=")))
end
_2amodule_2a["decode-payload"] = decode_payload
--[[ (decode-payload (jwt)) ]]
local function prompt_handler(cb)
  local function _1_(err, result, ctx, config)
    if err then
      return cb.error(core.get(err, "extension/id"), err)
    else
      local content = result.content
      if (core.get(content, "complete") or core.get(content, "function_call") or core.get(content, "content")) then
        return cb.content(core.get(result, "extension/id"), content)
      else
        return cb.error(core.get(result, "extension/id"), core.str("content not recognized: ", result))
      end
    end
  end
  return _1_
end
_2amodule_2a["prompt-handler"] = prompt_handler
local function exit_handler(cb)
  local function _4_(err, result, ctx, config)
    if err then
      return cb.error(core.get(err, "extension/id"), err)
    else
      return cb.exit(core.get(result, "extension/id"), result)
    end
  end
  return _4_
end
_2amodule_2a["exit-handler"] = exit_handler
local function jwt_handler(err, result, ctx, config)
  if err then
    core.println("jwt err: ", err)
  else
  end
  return jwt()
end
_2amodule_2a["jwt-handler"] = jwt_handler
local function start_lsps(prompt_handler0, exit_handler0)
  local root_dir = util["git-root"]()
  local extra_handlers = {["docker/jwt"] = jwt_handler}
  vim.lsp.start({name = "docker_ai", cmd = {"docker", "run", "--rm", "--init", "--interactive", "docker/labs-assistant-ml:staging"}, root_dir = root_dir, handlers = core.merge({["$/prompt"] = prompt_handler0, ["$/exit"] = exit_handler0}, extra_handlers)})
  return lsps.start(root_dir, extra_handlers)
end
_2amodule_2a["start-lsps"] = start_lsps
local function stop()
  local docker_lsp = (lsps["get-client-by-name"]("docker_lsp")).id
  local docker_ai = (lsps["get-client-by-name"]("docker_ai")).id
  if docker_lsp then
    vim.lsp.stop_client(docker_lsp, false)
  else
  end
  if docker_ai then
    return vim.lsp.stop_client(docker_ai, false)
  else
    return nil
  end
end
_2amodule_2a["stop"] = stop
local registrations = {}
local function run_prompt(question_id, callback, prompt)
  do local _ = {["fnl/docstring"] = "call Docker AI and register callback for this question identifier", ["fnl/arglist"] = {question_id, callback, prompt}} end
  registrations = core.assoc(registrations, question_id, callback)
  local docker_ai_lsp = lsps["get-client-by-name"]("docker_ai")
  local docker_lsp = lsps["get-client-by-name"]("docker_lsp")
  local result
  local _9_
  do
    local k = jwt()
    _9_ = {jwt = k, parsedJWT = decode_payload(k)}
  end
  result = docker_ai_lsp.request_sync("prompt", core.merge((docker_lsp.request_sync("docker/project-facts", {["vs-machine-id"] = ""}, 60000)).result, {["extension/id"] = question_id, question = {prompt = prompt}}, {dockerImagesResult = {}, dockerPSResult = {}, dockerDFResult = {}, dockerCredential = _9_, platform = {arch = "arm64", platform = "darwin", release = "23.0.0"}, vsMachineId = "", isProduction = true, notebookOpens = 1, notebookCloses = 1, notebookUUID = "", dataTrackTimestamp = 0, stream = true}))
  return core.println(result)
end
_2amodule_2a["run-prompt"] = run_prompt
local function questions()
  local docker_ai_lsp = lsps["get-client-by-name"]("docker_ai")
  local docker_lsp = lsps["get-client-by-name"]("docker_lsp")
  local result = (docker_lsp.request_sync("docker/project-facts", {["vs-machine-id"] = ""}, 60000)).result
  return core.concat(result["project/potential-questions"], {"Summarize this project", "Can you write a Dockerfile for this project", "How do I build this Docker project?", "Custom Question"})
end
_2amodule_2a["questions"] = questions
local function complain(_10_)
  local _arg_11_ = _10_
  local path = _arg_11_["path"]
  local language_id = _arg_11_["languageId"]
  local start_line = _arg_11_["startLine"]
  local end_line = _arg_11_["endLine"]
  local edit = _arg_11_["edit"]
  local reason = _arg_11_["reason"]
  local docker_lsp = lsps["get-client-by-name"]("docker_lsp")
  local params
  local _12_
  if end_line then
    _12_ = (end_line - 1)
  else
    _12_ = (start_line - 1)
  end
  params = {uri = {external = ("file://" .. path)}, message = reason, range = {start = {line = core.dec(start_line), character = 0}, ["end"] = {line = _12_, character = -1}}, edit = edit}
  return docker_lsp.request_sync("docker/complain", params, 10000)
end
_2amodule_2a["complain"] = complain
local function into_buffer(prompt)
  local lines = string.split(prompt, "\n")
  local _let_14_ = util.open(lines)
  local win = _let_14_[1]
  local buf = _let_14_[2]
  local t = util["show-spinner"](buf, core.inc(core.count(lines)))
  nvim.buf_set_lines(buf, -1, -1, false, {"", ""})
  local function _15_(extension_id, message)
    t:stop()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    else
    end
    return notebook["docker-ai-content-handler"](extension_id, message)
  end
  local function _17_(_, message)
    return core.println(core.str("error: ", message))
  end
  local function _18_(id, message)
    return core.println(core.str("finished prompt ", prompt), id)
  end
  return run_prompt(util.uuid(), {content = _15_, error = _17_, exit = _18_}, prompt)
end
_2amodule_2a["into-buffer"] = into_buffer
local function start()
  local cb
  local function _19_(id, message)
    return registrations[id].exit(id, message)
  end
  local function _20_(id, message)
    return core.println(id, message)
  end
  local function _21_(id, message)
    return registrations[id].content(id, message)
  end
  cb = {exit = _19_, error = _20_, content = _21_}
  return start_lsps(prompt_handler(cb), exit_handler(cb))
end
_2amodule_2a["start"] = start
local function update_buf(buf, lines)
  local function _22_()
    vim.cmd("norm! G")
    return vim.api.nvim_put(lines, "", true, true)
  end
  return vim.api.nvim_buf_call(buf, _22_)
end
_2amodule_2a["update-buf"] = update_buf
local function callback(buf)
  local function _23_(id, message)
    return update_buf(buf, {id, vim.json.encode(message), "----", ""})
  end
  local function _24_(id, message)
    return update_buf(buf, {id, vim.json.encode(message), "----", ""})
  end
  local function _25_(id, message)
    return update_buf(buf, {id, vim.json.encode(message), "----", ""})
  end
  return {exit = _23_, error = _24_, content = _25_}
end
_2amodule_2a["callback"] = callback
local function bottom_terminal(cmd)
  local current_win = nvim.tabpage_get_win(0)
  local original_buf = nvim.win_get_buf(current_win)
  local term_buf = nvim.create_buf(false, true)
  vim.cmd("split")
  local new_win = nvim.tabpage_get_win(0)
  nvim.win_set_buf(new_win, term_buf)
  return nvim.fn.termopen(cmd)
end
_2amodule_2a["bottom-terminal"] = bottom_terminal
--[[ (def buf (vim.api.nvim_create_buf true true)) (start) (lsps.list) (stop) (run-prompt "18" (callback buf) "Can you write a Dockerfile for this project?") (run-prompt "19" (callback buf) "Summarize this project") (run-prompt "21" (callback buf) "How do I dockerize my project") (run-prompt "22" (callback buf) "How do I build this Docker project?") ]]
local function lsp_debug(_)
  local function _26_(item)
    return item:gsub("_", " ")
  end
  local function _27_(selected, _0)
    local client = lsps["get-client-by-name"]("docker_lsp")
    return client.request_sync("docker/debug", {type = selected})
  end
  return vim.ui.select({"documents", "project-context", "tracking-data", "login", "alpine-packages", "repositories", "client-settings"}, {prompt = "Select a prompt:", format = _26_}, _27_)
end
_2amodule_2a["lsp-debug"] = lsp_debug
vim.api.nvim_create_user_command("DockerAIStart", start, {desc = "Start the LSPs for Docker AI"})
vim.api.nvim_create_user_command("DockerAIStop", stop, {desc = "Stop the LSPs for Docker AI"})
vim.api.nvim_create_user_command("DockerAIDebug", lsp_debug, {desc = "Get some state from the Docker LSP"})
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
local function set_team_id(args)
  local clients = vim.lsp.get_active_clients()
  for n, client in pairs(clients) do
    if (client.name == "docker_lsp") then
      local result = client.request_sync("docker/team-id", args, 5000)
      print(result)
    else
    end
  end
  return nil
end
_2amodule_2a["set_team_id"] = set_team_id
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
      local result = client.request_sync("docker/login", args, 5000)
      print(result)
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
nvim.create_user_command("DockerWorkspace", set_team_id, {nargs = "?"})
nvim.create_user_command("DockerServerInfo", docker_server_info, {nargs = "?"})
nvim.create_user_command("DockerLogin", docker_login, {nargs = "?"})
nvim.create_user_command("DockerLogout", docker_logout, {nargs = "?"})
nvim.create_user_command("DockerTailServerInfo", tail_server_info, {nargs = "?"})
return _2amodule_2a