local _2afile_2a = "fnl/nano-copilot.fnl"
local _2amodule_name_2a = "nano-copilot"
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
local core, curl, lsps, nvim, str, util, job = autoload("aniseed.core"), autoload("plenary.curl"), autoload("lsps"), autoload("aniseed.nvim"), autoload("aniseed.string"), autoload("slim.nvim"), require("plenary.job")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["curl"] = curl
_2amodule_locals_2a["lsps"] = lsps
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["str"] = str
_2amodule_locals_2a["util"] = util
_2amodule_locals_2a["job"] = job
local function open(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  nvim.buf_set_text(buf, 0, 0, 0, 0, lines)
  return util["open-win"](buf, {title = "Copilot"})
end
_2amodule_2a["open"] = open
--[[ (open ["hey"]) ]]
local function openselection()
  return open(util["get-current-buffer-selection"]())
end
_2amodule_2a["openselection"] = openselection
local function ollama(system_prompt, prompt, cb)
  local function _1_(_, chunk, _0)
    return cb(vim.json.decode(chunk).response)
  end
  return curl.post("http://localhost:11434/api/generate", {body = vim.json.encode({model = "llama3.1", prompt = prompt, system = system_prompt, stream = true}), stream = _1_})
end
_2amodule_2a["ollama"] = ollama
local function execute_prompt(prompt)
  local function _2_(...)
    return ollama("", ...)
  end
  return util["stream-into-buffer"](_2_, prompt)
end
_2amodule_2a["execute-prompt"] = execute_prompt
--[[ (execute-prompt "What does a Dockerfile look like?") (vim.fn.input "Question: ") ]]
local function copilot()
  local prompts = {"ask", "ask about snippet"}
  local function _3_(selected, _)
    if (selected == "ask about snippet") then
      return execute_prompt(("\n\n Here is a code snippet that I'm working on:\n```\n" .. str.join("\n", util["get-current-buffer-selection"]()) .. "\n```\n\n" .. vim.fn.input("Ask Assistant: ")))
    else
      return execute_prompt(str.join("\n", util["get-current-buffer-selection"]()))
    end
  end
  return vim.ui.select(prompts, {prompt = "Select LLM"}, _3_)
end
_2amodule_2a["copilot"] = copilot
nvim.set_keymap("v", "<leader>ai", ":lua require('nano-copilot').copilot()<CR>", {})
--[[ (lsps.list) ]]
return _2amodule_2a