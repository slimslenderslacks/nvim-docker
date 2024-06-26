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
local function prompt_runner(args, message_callback, functions_callback)
  local function _1_(err, data)
    local function _2_(m)
      local _3_ = m
      if ((_G.type(_3_) == "table") and ((_3_).method == "message") and (nil ~= (_3_).params)) then
        local x = (_3_).params
        return message_callback(core.get(x, "content"))
      elseif ((_G.type(_3_) == "table") and ((_3_).method == "functions") and (nil ~= (_3_).params)) then
        local x = (_3_).params
        return functions_callback(core.str(x))
      elseif ((_G.type(_3_) == "table") and ((_3_).method == "functions-done") and (nil ~= (_3_).params)) then
        local x = (_3_).params
        return functions_callback(core.str(x))
      elseif ((_G.type(_3_) == "table") and (nil ~= (_3_).error) and (nil ~= (_3_).data)) then
        local err0 = (_3_).error
        local d = (_3_).data
        return message_callback(core.str(string.format("%s\n%s", err0, d)))
      elseif true then
        local _ = _3_
        return message_callback(core.str("-->\n", data))
      else
        return nil
      end
    end
    local function _5_()
      if data then
        return jsonrpc.messages(data)
      else
        return {}
      end
    end
    return core.map(_2_, _5_())
  end
  local function _6_(err, data)
    return message_callback(data)
  end
  local function _9_(_7_)
    local _arg_8_ = _7_
    local code = _arg_8_["code"]
    local signal = _arg_8_["signal"]
    local data = _arg_8_
  end
  return vim.system(args, {text = true, stdout = _1_, stderr = _6_, stdin = false}, _9_)
end
_2amodule_2a["prompt-runner"] = prompt_runner
local function execute_prompt(type)
  local function _10_(messages_callback, functions_callback)
    return prompt_runner({"docker", "run", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock", "--mount", "type=volume,source=docker-prompts,target=/prompts", "--mount", string.format("type=bind,source=%s,target=/project", vim.fn.getcwd()), "--mount", "type=bind,source=/Users/slim/.openai-api-key,target=/root/.openai-api-key", "vonwig/prompts:local", "run", "--jsonrpc", vim.fn.getcwd(), "jimclark106", "darwin", type}, messages_callback, functions_callback)
  end
  return util["start-streaming"](_10_)
end
_2amodule_2a["execute-prompt"] = execute_prompt
local function prompt_run()
  local prompts = {"github:docker/labs-githooks?ref=main&path=prompts/git_hooks_just_llm", "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_with_linguist", "github:docker/labs-githooks?ref=main&path=prompts/git_hooks", "github:docker/labs-githooks?ref=slim/prompts/input&path=prompts/git_hooks_single_step"}
  local function _11_(selected, _)
    return execute_prompt(selected)
  end
  return vim.ui.select(prompts, {prompt = "Select LLM"}, _11_)
end
_2amodule_2a["prompt-run"] = prompt_run
local promptRun = prompt_run
_2amodule_2a["promptRun"] = promptRun
--[[ (prompt-run) ]]
nvim.set_keymap("n", "<leader>assist", ":lua require('prompts.runner').promptRun()<CR>", {})
return _2amodule_2a