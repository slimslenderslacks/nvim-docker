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
local core, lsps, nvim, string, util = autoload("aniseed.core"), autoload("lsps"), autoload("aniseed.nvim"), autoload("aniseed.string"), autoload("slim.nvim")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["lsps"] = lsps
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
        local function _3_()
          if core.get(content, "function_call") then
            local function _2_(fc)
              return core.assoc(fc, "arguments", vim.json.decode(core.get(fc, "arguments")))
            end
            return core.update(content, "function_call", _2_)
          else
            return content
          end
        end
        return cb.content(core.get(result, "extension/id"), _3_())
      else
        return nil
      end
    end
  end
  return _1_
end
_2amodule_2a["prompt-handler"] = prompt_handler
local function exit_handler(cb)
  local function _6_(err, result, ctx, config)
    if err then
      return cb.error(core.get(err, "extension/id"), err)
    else
      return cb.exit(core.get(result, "extension/id"), result)
    end
  end
  return _6_
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
  registrations = core.assoc(registrations, question_id, callback)
  local docker_ai_lsp = lsps["get-client-by-name"]("docker_ai")
  local docker_lsp = lsps["get-client-by-name"]("docker_lsp")
  local result
  local _11_
  do
    local k = jwt()
    _11_ = {jwt = k, parsedJWT = decode_payload(k)}
  end
  result = docker_ai_lsp.request_sync("prompt", core.merge((docker_lsp.request_sync("docker/project-facts", {["vs-machine-id"] = ""}, 60000)).result, {["extension/id"] = question_id, question = {prompt = prompt}}, {dockerImagesResult = {}, dockerPSResult = {}, dockerDFResult = {}, dockerCredential = _11_, platform = {arch = "arm64", platform = "darwin", release = "23.0.0"}, vsMachineId = "", isProduction = true, notebookOpens = 1, notebookCloses = 1, notebookUUID = "", dataTrackTimestamp = 0, stream = true}))
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
local function update_buf(buf, lines)
  local function _12_()
    vim.cmd("norm! G")
    return vim.api.nvim_put(lines, "", true, true)
  end
  return vim.api.nvim_buf_call(buf, _12_)
end
_2amodule_2a["update-buf"] = update_buf
local function complain(_13_)
  local _arg_14_ = _13_
  local path = _arg_14_["path"]
  local language_id = _arg_14_["languageId"]
  local start_line = _arg_14_["startLine"]
  local end_line = _arg_14_["endLine"]
  local edit = _arg_14_["edit"]
  local reason = _arg_14_["reason"]
  local docker_lsp = lsps["get-client-by-name"]("docker_lsp")
  local params
  local _15_
  if end_line then
    _15_ = (end_line - 1)
  else
    _15_ = (start_line - 1)
  end
  params = {uri = {external = ("file://" .. path)}, message = reason, range = {start = {line = core.dec(start_line), character = 0}, ["end"] = {line = _15_, character = -1}}, edit = edit}
  return docker_lsp.request_sync("docker/complain", params, 10000)
end
_2amodule_2a["complain"] = complain
local function append(current_lines, s)
  return core.str(string.join("\n", current_lines), s)
end
_2amodule_2a["append"] = append
local function docker_ai_content_handler(current_lines, message)
  if message.content then
    return string.split(append(current_lines, message.content), "\n")
  elseif (message.function_call and ((message.function_call.name == "cell-execution") or (message.function_call.name == "suggest-command"))) then
    return core.concat(current_lines, {"", "```bash"}, string.split(message.function_call.arguments.command, "\n"), {"```", ""})
  elseif (message.function_call and (message.function_call.name == "update-file")) then
    local _let_17_ = message.function_call.arguments
    local path = _let_17_["path"]
    util["open-file"](path)
    complain(message.function_call.arguments)
    return core.concat(current_lines, {"", "I've opened a buffer to the right and created a code action for your review."})
  elseif (message.function_call and (message.function_call.name == "create-notebook")) then
    local _let_18_ = message.function_call.arguments
    local notebook = _let_18_["notebook"]
    local cells = _let_18_["cells"]
    local notebook_content
    local function _21_(_19_)
      local _arg_20_ = _19_
      local kind = _arg_20_["kind"]
      local value = _arg_20_["value"]
      local language_id = _arg_20_["languageId"]
      return core.concat({("```" .. language_id)}, string.split(value, "\n"), {"```", ""})
    end
    notebook_content = core.mapcat(_21_, cells.cells)
    local buf = util["open-file"](notebook)
    util.append(buf, notebook_content)
    return core.concat(current_lines, {"", "I've opened a new notebook to the right."})
  elseif (message.function_call and (message.function_call.name == "show-notification")) then
    local _let_22_ = message.function_call.arguments
    local level = _let_22_["level"]
    local message0 = _let_22_["message"]
    local actions = _let_22_["actions"]
    vim.api.nvim_notify(message0, vim.log.levels.INFO, {})
    return core.concat(current_lines, {""})
  elseif message.complete then
    return core.concat(current_lines, {""})
  else
    return core.concat(current_lines, {"", "```json", vim.json.encode(message), "```", ""})
  end
end
_2amodule_2a["docker-ai-content-handler"] = docker_ai_content_handler
local function into_buffer(prompt)
  local lines = string.split(prompt, "\n")
  local _let_24_ = util.open(lines)
  local win = _let_24_[1]
  local buf = _let_24_[2]
  local t = util["show-spinner"](buf, core.inc(core.count(lines)))
  nvim.buf_set_lines(buf, -1, -1, false, {"", ""})
  local function _25_(_, message)
    t:stop()
    local current_lines = vim.api.nvim_buf_get_lines(buf, 4, -1, false)
    local lines0 = docker_ai_content_handler(current_lines, message)
    return vim.api.nvim_buf_set_lines(buf, 4, -1, false, lines0)
  end
  local function _26_(_, message)
    return core.println(message)
  end
  local function _27_(id, message)
    return core.println("finished", id)
  end
  return run_prompt(util.uuid(), {content = _25_, error = _26_, exit = _27_}, prompt)
end
_2amodule_2a["into-buffer"] = into_buffer
local function start()
  local cb
  local function _28_(id, message)
    return registrations[id].exit(id, message)
  end
  local function _29_(id, message)
    return core.println(id, message)
  end
  local function _30_(id, message)
    return registrations[id].content(id, message)
  end
  cb = {exit = _28_, error = _29_, content = _30_}
  return start_lsps(prompt_handler(cb), exit_handler(cb))
end
_2amodule_2a["start"] = start
local function callback(buf)
  local function _31_(id, message)
    return update_buf(buf, {id, vim.json.encode(message), "----", ""})
  end
  local function _32_(id, message)
    return update_buf(buf, {id, vim.json.encode(message), "----", ""})
  end
  local function _33_(id, message)
    return update_buf(buf, {id, vim.json.encode(message), "----", ""})
  end
  return {exit = _31_, error = _32_, content = _33_}
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
  local function _34_(item)
    return item:gsub("_", " ")
  end
  local function _35_(selected, _0)
    local client = lsps["get-client-by-name"]("docker_lsp")
    return client.request_sync("docker/debug", {type = selected})
  end
  return vim.ui.select({"documents", "project-context", "tracking-data", "login", "alpine-packages", "repositories", "client-settings"}, {prompt = "Select a prompt:", format = _34_}, _35_)
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
return _2amodule_2a