local _2afile_2a = "fnl/prompts/runner.fnl"
local _2amodule_name_2a = "prompts.runner"
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
local core, curl, fs, jsonrpc, nvim, rpc, str, util = autoload("aniseed.core"), autoload("plenary.curl"), autoload("aniseed.fs"), autoload("jsonrpc"), autoload("aniseed.nvim"), autoload("vim.lsp.rpc"), autoload("aniseed.string"), autoload("slim.nvim")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["curl"] = curl
_2amodule_locals_2a["fs"] = fs
_2amodule_locals_2a["jsonrpc"] = jsonrpc
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["rpc"] = rpc
_2amodule_locals_2a["str"] = str
_2amodule_locals_2a["util"] = util
local debug = false
local use_docker = false
local hostdir = nil
local prompt_engine = nil
local function update_buffer(m, message_callback, functions_callback)
  local _1_ = m
  if ((_G.type(_1_) == "table") and ((_1_).method == "start") and (nil ~= (_1_).params)) then
    local x = (_1_).params
    local _2_
    do
      local s = ""
      for i = 0, core.inc(core.get(x, "level")) do
        s = core.str(s, "#")
      end
      _2_ = s
    end
    local function _3_()
      local s = core.get(x, "content")
      if s then
        return string.format("(%s)", s)
      else
        return ""
      end
    end
    return message_callback(string.format("\n%s ROLE %s%s\n", _2_, core.get(x, "role"), _3_()))
  elseif ((_G.type(_1_) == "table") and ((_1_).method == "message") and (nil ~= (_1_).params)) then
    local x = (_1_).params
    if core.get(x, "content") then
      return message_callback(core.get(x, "content"))
    elseif debug then
      return message_callback(core.get(x, "debug"))
    else
      return message_callback(core.get(x, "content"))
    end
  elseif ((_G.type(_1_) == "table") and ((_1_).method == "functions") and (nil ~= (_1_).params)) then
    local x = (_1_).params
    return functions_callback(core.str(x))
  elseif ((_G.type(_1_) == "table") and ((_1_).method == "functions-done") and (nil ~= (_1_).params)) then
    local x = (_1_).params
    return functions_callback(core.str("\n"))
  elseif ((_G.type(_1_) == "table") and ((_1_).method == "prompts") and (nil ~= (_1_).params)) then
    local x = (_1_).params
    return message_callback("")
  elseif ((_G.type(_1_) == "table") and ((_1_).method == "error") and (nil ~= (_1_).params)) then
    local x = (_1_).params
    message_callback(string.format("\n```error\n%s\n```\n", core.get(x, "content")))
    if (debug and core.get(x, "exception")) then
      return message_callback(core.get(x, "exception"))
    else
      return nil
    end
  elseif ((_G.type(_1_) == "table") and (nil ~= (_1_).error) and (nil ~= (_1_).data)) then
    local err = (_1_).error
    local d = (_1_).data
    return message_callback(core.str(string.format("\nerr--> %s\n%s", err, d)))
  elseif true then
    local _ = _1_
    return message_callback(core.str("-->\n", ""))
  else
    return nil
  end
end
_2amodule_2a["update-buffer"] = update_buffer
local function prompt_runner(args, message_callback, functions_callback)
  local function _8_(method, params)
    return update_buffer({method = method, params = params}, message_callback, functions_callback)
  end
  prompt_engine = rpc.start(args, {notification = _8_}, {cwd = "/Users/slim/docker/labs-ai-tools-for-devs/"})
  return nil
end
_2amodule_2a["prompt-runner"] = prompt_runner
local function basedir()
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
end
_2amodule_2a["basedir"] = basedir
local function relativize(base, f)
  return vim.fn.fnamemodify(f, ":.")
end
_2amodule_2a["relativize"] = relativize
local function getHostdir()
  return (hostdir or vim.fn.getcwd())
end
_2amodule_2a["getHostdir"] = getHostdir
--[[ (get-hostdir) (core.println hostdir) ]]
local function docker_command(f)
  return {"docker", "run", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock", "-v", "/run/host-services/backend.sock:/lsp-server/docker-desktop-backend.sock", "-e", "DOCKER_DESKTOP_SOCKET_PATH=/lsp-server/docker-desktop-backend.sock", "-e", "OPENAI_API_KEY_LOCATION=/root", "--mount", "type=volume,source=docker-prompts,target=/prompts", "--mount", "type=bind,source=/Users/slim/.openai-api-key,target=/root/.openai-api-key", "--mount", string.format("type=bind,source=%s,target=/app/workdir", vim.fn.getcwd()), "--workdir", "/app/workdir", "vonwig/prompts:latest", "run", "--jsonrpc", "--host-dir", getHostdir(), "--platform", "darwin", "--prompts-file", relativize(vim.fn.getcwd(), f)}
end
_2amodule_2a["docker-command"] = docker_command
local function bb_command(f)
  return {"clj", "-M:main", "run", "--jsonrpc", "--host-dir", getHostdir(), "--platform", "darwin", "--thread-id", "thread", "--prompts-file", f}
end
_2amodule_2a["bb-command"] = bb_command
local function bb_prompt_command(f)
  return {"clj", "-M:main", "--jsonrpc", "--host-dir", getHostdir(), "--platform", "darwin", "--prompts-file", f}
end
_2amodule_2a["bb-prompt-command"] = bb_prompt_command
local function execute_prompt(type)
  vim.cmd("split")
  vim.cmd("resize +10")
  local function _9_(messages_callback, functions_callback)
    local function _10_()
      if debug then
        return {"--debug"}
      else
        return {}
      end
    end
    return prompt_runner(core.concat(docker_command(), {"--prompts", type}, _10_()), messages_callback, functions_callback)
  end
  return util["start-streaming"](_9_)
end
_2amodule_2a["execute-prompt"] = execute_prompt
local function execute_local_prompt_without_docker()
  local f = vim.api.nvim_buf_get_name(0)
  vim.cmd("split")
  vim.cmd("resize +10")
  local function _11_(messages_callback, functions_callback)
    local _12_
    if use_docker then
      _12_ = docker_command(f)
    else
      _12_ = bb_command(f)
    end
    local function _14_()
      if debug then
        return {"--debug"}
      else
        return {}
      end
    end
    return prompt_runner(core.concat(_12_, _14_()), messages_callback, functions_callback)
  end
  return util["start-streaming"](_11_)
end
_2amodule_2a["execute-local-prompt-without-docker"] = execute_local_prompt_without_docker
local function execute_local_prompt_generate()
  local f = vim.api.nvim_buf_get_name(0)
  vim.cmd("split")
  vim.cmd("resize +10")
  local function _15_(messages_callback, functions_callback)
    local function _16_()
      if debug then
        return {"--debug"}
      else
        return {}
      end
    end
    return prompt_runner(core.concat(bb_prompt_command(f), _16_()), messages_callback, functions_callback)
  end
  return util["start-streaming"](_15_)
end
_2amodule_2a["execute-local-prompt-generate"] = execute_local_prompt_generate
local function prompt_run()
  local prompts = {"github:docker/labs-githooks?ref=main&path=prompts/git_hooks_just_llm", "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_with_linguist", "github:docker/labs-githooks?ref=main&path=prompts/git_hooks", "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_single_step", "github:docker/labs-make-runbook?ref=main&path=prompts/dockerfiles"}
  local function _17_(selected, _)
    return execute_prompt(selected)
  end
  return vim.ui.select(prompts, {prompt = "Select LLM"}, _17_)
end
_2amodule_2a["prompt-run"] = prompt_run
local function localPromptRun()
  return execute_local_prompt_without_docker()
end
_2amodule_2a["localPromptRun"] = localPromptRun
local function localPromptList()
  return execute_local_prompt_generate()
end
_2amodule_2a["localPromptList"] = localPromptList
local promptRun = prompt_run
_2amodule_2a["promptRun"] = promptRun
--[[ (prompt-run) ]]
nvim.set_keymap("n", "<leader>assist", ":lua require('prompts.runner').promptRun()<CR>", {})
nvim.set_keymap("n", "<leader>pr", ":lua require('prompts.runner').localPromptRun()<CR>", {})
nvim.set_keymap("n", "<leader>pl", ":lua require('prompts.runner').localPromptList()<CR>", {})
local function _20_(_18_)
  local _arg_19_ = _18_
  local args = _arg_19_["args"]
  hostdir = vim.fn.fnamemodify(args, ":p")
  return nil
end
nvim.create_user_command("PromptsSetHostdir", _20_, {desc = "set prompts hostdir", nargs = 1, complete = "dir"})
local function _21_(_)
  debug = not debug
  return core.println(core.str("debug ", debug))
end
nvim.create_user_command("PromptsToggleDebug", _21_, {desc = "toggle prompts debug", nargs = 0})
local function _22_(_)
  use_docker = not use_docker
  return core.println(core.str("use-docker ", use_docker))
end
nvim.create_user_command("PromptsToggleUseDocker", _22_, {desc = "toggle prompts use of docker", nargs = 0})
local function _23_(_)
  return core.println(string.format("HostDir: %s\nDebug: %s\nUseDocker: %s\n", getHostdir(), debug, use_docker))
end
nvim.create_user_command("PromptsGetConfigr", _23_, {desc = "get prompts hostdir", nargs = 0})
local function _24_(_)
  return prompt_engine:terminate()
end
nvim.create_user_command("PromptsExitEngine", _24_, {desc = "exit a prompt engine", nargs = 0})
return _2amodule_2a