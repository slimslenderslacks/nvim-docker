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
local core, curl, fs, jsonrpc, nvim, str, util = autoload("aniseed.core"), autoload("plenary.curl"), autoload("aniseed.fs"), autoload("jsonrpc"), autoload("aniseed.nvim"), autoload("aniseed.string"), autoload("slim.nvim")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["curl"] = curl
_2amodule_locals_2a["fs"] = fs
_2amodule_locals_2a["jsonrpc"] = jsonrpc
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["str"] = str
_2amodule_locals_2a["util"] = util
local debug = false
local function prompt_runner(args, message_callback, functions_callback)
  local function _1_(err, data)
    local function _2_(m)
      local _3_ = m
      if ((_G.type(_3_) == "table") and ((_3_).method == "message") and (nil ~= (_3_).params)) then
        local x = (_3_).params
        if core.get(x, "content") then
          return message_callback(core.get(x, "content"))
        elseif debug then
          return message_callback(core.get(x, "debug"))
        else
          return message_callback(core.get(x, "content"))
        end
      elseif ((_G.type(_3_) == "table") and ((_3_).method == "functions") and (nil ~= (_3_).params)) then
        local x = (_3_).params
        return functions_callback(core.str(x))
      elseif ((_G.type(_3_) == "table") and ((_3_).method == "functions-done") and (nil ~= (_3_).params)) then
        local x = (_3_).params
        return functions_callback(core.str("\n"))
      elseif ((_G.type(_3_) == "table") and (nil ~= (_3_).error) and (nil ~= (_3_).data)) then
        local err0 = (_3_).error
        local d = (_3_).data
        return message_callback(core.str(string.format("%s\n%s", err0, d)))
      elseif ((_G.type(_3_) == "table") and ((_3_).method == "prompts") and (nil ~= (_3_).params)) then
        local x = (_3_).params
        return message_callback("")
      elseif true then
        local _ = _3_
        return message_callback(core.str("-->\n", data))
      else
        return nil
      end
    end
    local function _6_()
      if data then
        return jsonrpc.messages(data)
      else
        return {}
      end
    end
    return core.map(_2_, _6_())
  end
  local function _7_(err, data)
    return message_callback(data)
  end
  local function _10_(_8_)
    local _arg_9_ = _8_
    local code = _arg_9_["code"]
    local signal = _arg_9_["signal"]
    local data = _arg_9_
  end
  return vim.system(args, {text = true, cwd = "/Users/slim/docker/labs-ai-tools-for-devs/", stdout = _1_, stderr = _7_, stdin = false}, _10_)
end
_2amodule_2a["prompt-runner"] = prompt_runner
local function execute_prompt(type)
  local function _11_(messages_callback, functions_callback)
    return prompt_runner({"docker", "run", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock", "--mount", "type=volume,source=docker-prompts,target=/prompts", "--mount", string.format("type=bind,source=%s,target=/project", vim.fn.getcwd()), "--mount", "type=bind,source=/Users/slim/.openai-api-key,target=/root/.openai-api-key", "vonwig/prompts:local", "run", "--jsonrpc", "--host-dir", vim.fn.getcwd(), "--user", "jimclark106", "--platform", "darwin", "--prompts", type}, messages_callback, functions_callback)
  end
  return util["start-streaming"](_11_)
end
_2amodule_2a["execute-prompt"] = execute_prompt
local function basedir()
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
end
_2amodule_2a["basedir"] = basedir
local hostdir = "/Users/slim/docker/labs-make-runbook/"
local function getHostdir()
  return hostdir
end
_2amodule_2a["getHostdir"] = getHostdir
--[[ (get-hostdir) (core.println hostdir) ]]
local function execute_local_prompt_without_docker()
  local f = vim.api.nvim_buf_get_name(0)
  vim.cmd("split")
  vim.cmd("resize +10")
  local function _12_(messages_callback, functions_callback)
    local args
    local function _13_()
      if debug then
        return {"--debug"}
      else
        return {}
      end
    end
    args = core.concat({"bb", "-m", "prompts", "run", "--jsonrpc", "--host-dir", getHostdir(), "--user", "jimclark106", "--platform", "darwin", "--prompts-file", f}, _13_())
    return prompt_runner(args, messages_callback, functions_callback)
  end
  return util["start-streaming"](_12_)
end
_2amodule_2a["execute-local-prompt-without-docker"] = execute_local_prompt_without_docker
local function prompt_run()
  local prompts = {"github:docker/labs-githooks?ref=main&path=prompts/git_hooks_just_llm", "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_with_linguist", "github:docker/labs-githooks?ref=main&path=prompts/git_hooks", "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_single_step", "github:docker/labs-make-runbook?ref=main&path=prompts/dockerfiles"}
  local function _14_(selected, _)
    return execute_prompt(selected)
  end
  return vim.ui.select(prompts, {prompt = "Select LLM"}, _14_)
end
_2amodule_2a["prompt-run"] = prompt_run
local function localPromptRun()
  return execute_local_prompt_without_docker()
end
_2amodule_2a["localPromptRun"] = localPromptRun
local promptRun = prompt_run
_2amodule_2a["promptRun"] = promptRun
--[[ (prompt-run) ]]
nvim.set_keymap("n", "<leader>assist", ":lua require('prompts.runner').promptRun()<CR>", {})
nvim.set_keymap("n", "<leader>pr", ":lua require('prompts.runner').localPromptRun()<CR>", {})
local function _17_(_15_)
  local _arg_16_ = _15_
  local args = _arg_16_["args"]
  hostdir = args
  return nil
end
nvim.create_user_command("PromptsSetHostdir", _17_, {desc = "set prompts hostdir", nargs = 1, complete = "dir"})
local function _18_(_)
  debug = not debug
  return core.println(core.str("debug ", debug))
end
nvim.create_user_command("PromptsToggleDebug", _18_, {desc = "toggle prompts debug", nargs = 0})
local function _19_(_)
  return core.println(core.str("HostDir: ", getHostdir()))
end
nvim.create_user_command("PromptsGetHostdir", _19_, {desc = "get prompts hostdir", nargs = 0})
return _2amodule_2a