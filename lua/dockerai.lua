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
local core, nvim, string, util, lsps, notebook = autoload("aniseed.core"), autoload("aniseed.nvim"), autoload("aniseed.string"), autoload("slim.nvim"), require("lsps"), require("notebook")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["string"] = string
_2amodule_locals_2a["util"] = util
_2amodule_locals_2a["lsps"] = lsps
_2amodule_locals_2a["notebook"] = notebook
vim.lsp.set_log_level("TRACE")
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
      elseif core.get(result, "extension/id") then
        return cb.error(core.get(result, "extension/id"), core.str("content not recognized: ", result))
      else
        return nil
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
nvim.set_keymap("v", "<leader>ai", ":lua require('copilot').openselection()<CR>", {})
local function start_lsps(prompt_handler0, exit_handler0)
  local root_dir = vim.fn.getcwd()
  local extra_handlers = {["docker/jwt"] = lsps["jwt-handler"], ["$terminal/run"] = lsps["terminal-run-handler"], ["$bind/run"] = lsps["terminal-bind-handler"]}
  lsps["start-dockerai-lsp"](root_dir, extra_handlers, prompt_handler0, exit_handler0)
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
local streaming_3f = true
local function run_prompt(question_id, callback, prompt)
  do local _ = {["fnl/docstring"] = "call Docker AI and register callback for this question identifier", ["fnl/arglist"] = {question_id, callback, prompt}} end
  registrations = core.assoc(registrations, question_id, callback)
  local docker_ai_lsp = lsps["get-client-by-name"]("docker_ai")
  local docker_lsp = lsps["get-client-by-name"]("docker_lsp")
  local result
  local _8_
  do
    local k = jwt()
    _8_ = {jwt = k, parsedJWT = decode_payload(k)}
  end
  result = docker_ai_lsp.request_sync("prompt", core.merge((docker_lsp.request_sync("docker/project-facts", {["vs-machine-id"] = ""}, 60000)).result, {["extension/id"] = question_id, question = {prompt = prompt}}, {dockerImagesResult = {}, dockerPSResult = {}, dockerDFResult = {}, dockerCredential = _8_, platform = {arch = "arm64", platform = "darwin", release = "23.0.0"}, vsMachineId = "", isProduction = true, notebookOpens = 1, notebookCloses = 1, notebookUUID = "", dataTrackTimestamp = 0, stream = streaming_3f}))
  return notebook["append-to-log"](string.split(core.str(result), "\n"))
end
_2amodule_2a["run-prompt"] = run_prompt
local function questions()
  local docker_ai_lsp = lsps["get-client-by-name"]("docker_ai")
  local docker_lsp = lsps["get-client-by-name"]("docker_lsp")
  local result = (docker_lsp.request_sync("docker/project-facts", {["vs-machine-id"] = ""}, 60000)).result
  local result2 = (docker_ai_lsp.request_sync("questions", {["extension/id"] = "id"})).result
  return core.concat(result["project/potential-questions"], (result2).content, {"Summarize this project", "Can you write a Dockerfile for this project", "How do I build this Docker project?", "Custom Question"})
end
_2amodule_2a["questions"] = questions
local function into_buffer(prompt)
  local lines = string.split(prompt, "\n")
  local _let_9_ = util.open(lines)
  local win = _let_9_[1]
  local buf = _let_9_[2]
  local t = util["show-spinner"](buf, core.inc(core.count(lines)))
  nvim.buf_set_lines(buf, -1, -1, false, {"", ""})
  local function _10_(extension_id, message)
    t:stop()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    else
    end
    return notebook["docker-ai-content-handler"](extension_id, message)
  end
  local function _12_(_, message)
    return notebook["append-to-log"](core.concat({core.str("ERROR: ")}, string.split(core.str(message), "\n")))
  end
  local function _13_(id, message)
    return notebook["append-to-log"](core.concat({core.str("finished prompt ", id)}, lines))
  end
  return run_prompt(util.uuid(), {content = _10_, error = _12_, exit = _13_}, prompt)
end
_2amodule_2a["into-buffer"] = into_buffer
local function runBufferPrompt()
  local bufnr = vim.api.nvim_get_current_buf()
  return core.println(pcall(into_buffer, string.join("\n", vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))))
end
_2amodule_2a["runBufferPrompt"] = runBufferPrompt
local function start()
  local cb
  local function _14_(id, message)
    return registrations[id].exit(id, message)
  end
  local function _15_(id, message)
    return notebook["append-to-log"](core.concat({core.str("ERROR: ", id, " - ")}, string.split(core.str(message), "\n")))
  end
  local function _16_(id, message)
    return registrations[id].content(id, message)
  end
  cb = {exit = _14_, error = _15_, content = _16_}
  return start_lsps(prompt_handler(cb), exit_handler(cb))
end
_2amodule_2a["start"] = start
local function update_buf(buf, lines)
  local function _17_()
    vim.cmd("norm! G")
    return vim.api.nvim_put(lines, "", true, true)
  end
  return vim.api.nvim_buf_call(buf, _17_)
end
_2amodule_2a["update-buf"] = update_buf
local function callback(buf)
  local function _18_(id, message)
    return update_buf(buf, {id, vim.json.encode(message), "----", ""})
  end
  local function _19_(id, message)
    return update_buf(buf, {id, vim.json.encode(message), "----", ""})
  end
  local function _20_(id, message)
    return update_buf(buf, {id, vim.json.encode(message), "----", ""})
  end
  return {exit = _18_, error = _19_, content = _20_}
end
_2amodule_2a["callback"] = callback
--[[ (def buf (vim.api.nvim_create_buf true true)) (start) (lsps.list) (stop) (run-prompt "18" (callback buf) "Can you write a Dockerfile for this project?") (run-prompt "19" (callback buf) "Summarize this project") (run-prompt "21" (callback buf) "How do I dockerize my project") (run-prompt "22" (callback buf) "How do I build this Docker project?") ]]
local function lsp_debug(_)
  local function _21_(item)
    return item:gsub("_", " ")
  end
  local function _22_(selected, _0)
    local client = lsps["get-client-by-name"]("docker_lsp")
    return client.request_sync("docker/debug", {type = selected})
  end
  return vim.ui.select({"documents", "project-context", "tracking-data", "login", "alpine-packages", "repositories", "client-settings"}, {prompt = "Choose Type of Data:", format = _21_}, _22_)
end
_2amodule_2a["lsp-debug"] = lsp_debug
local function setup(_23_)
  local _arg_24_ = _23_
  local cb = _arg_24_["attach"]
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
--[[ (vim.api.nvim_create_user_command "DockerAIStart" start {:desc "Start the LSPs for Docker AI"}) (vim.api.nvim_create_user_command "DockerAIStop" stop {:desc "Stop the LSPs for Docker AI"}) (vim.api.nvim_create_user_command "DockerAIToggleStreaming" (fn [] (set streaming? (not streaming?)) (core.println "now set to " streaming?)) {:desc "Toggle Streaming for Docker AI"}) (nvim.create_user_command "DockerLogout" docker_logout {:nargs "?"}) (nvim.create_user_command "DockerTailServerInfo" tail_server_info {:nargs "?"}) ]]
return _2amodule_2a