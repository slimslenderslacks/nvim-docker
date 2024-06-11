local _2afile_2a = "fnl/runbooks.fnl"
local _2amodule_name_2a = "runbooks"
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
local core, curl, fs, nvim, string, util = autoload("aniseed.core"), autoload("plenary.curl"), autoload("aniseed.fs"), autoload("aniseed.nvim"), autoload("aniseed.string"), autoload("slim.nvim")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["curl"] = curl
_2amodule_locals_2a["fs"] = fs
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["string"] = string
_2amodule_locals_2a["util"] = util
local opena_api_key = string.trim(core.slurp("/Users/slim/.open-api-key"))
do end (_2amodule_2a)["opena-api-key"] = opena_api_key
local function prompt_types()
  local obj = vim.system({"docker", "run", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock", "vonwig/prompts:latest", "prompts"}, {text = true})
  local _let_1_ = obj.wait(obj)
  local out = _let_1_["stdout"]
  local function _4_(agg, _2_)
    local _arg_3_ = _2_
    local title = _arg_3_["title"]
    local type = _arg_3_["type"]
    return core.assoc(agg, title, type)
  end
  return core.reduce(_4_, {}, vim.json.decode(out))
end
_2amodule_2a["prompt-types"] = prompt_types
local function prompts(type)
  local obj = vim.system({"docker", "run", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock", "--mount", "type=volume,source=docker-prompts,target=/prompts", "vonwig/prompts:latest", vim.fn.getcwd(), "jimclark106", "darwin", type}, {text = true})
  local _let_5_ = obj.wait(obj)
  local out = _let_5_["stdout"]
  local err = _let_5_["stderr"]
  return vim.json.decode(out)
end
_2amodule_2a["prompts"] = prompts
local function openai(messages, cb)
  local function _6_(_, chunk, _0)
    local function _7_(...)
      local _8_ = ...
      if (nil ~= _8_) then
        local s = _8_
        local function _9_(...)
          local _10_ = ...
          if (nil ~= _10_) then
            local s0 = _10_
            local function _11_(...)
              local _12_, _13_ = ...
              if ((_12_ == true) and (nil ~= _13_)) then
                local obj = _13_
                return core.first(obj.choices).delta.content
              elseif (nil ~= _12_) then
                local s1 = _12_
                return s1
              else
                return nil
              end
            end
            local function _15_()
              return vim.json.decode(s0)
            end
            return _11_(pcall(_15_))
          elseif (nil ~= _10_) then
            local s0 = _10_
            return s0
          else
            return nil
          end
        end
        local function _17_(...)
          if vim.startswith(s, "data:") then
            return s:sub(7)
          else
            return nil
          end
        end
        return _9_(_17_(...))
      elseif (nil ~= _8_) then
        local s = _8_
        return s
      else
        return nil
      end
    end
    return cb(_7_(chunk))
  end
  return curl.post("https://api.openai.com/v1/chat/completions", {body = vim.json.encode({model = "gpt-4", messages = messages, stream = true}), headers = {Authorization = core.str("Bearer ", opena_api_key), ["Content-Type"] = "application/json"}, stream = _6_})
end
_2amodule_2a["openai"] = openai
--[[ (prompt-types) (prompts "docker") (util.stream-into-empty-buffer openai (prompts "docker")) (openai (prompts "docker") (fn [s] (core.println s))) ]]
local function generate_runbook(_)
  local m = core.assoc(prompt_types(), "custom", "custom")
  local function _19_(selected, _0)
    local prompt_type
    if (selected == "custom") then
      prompt_type = vim.fn.input("prompt github ref: ")
    else
      prompt_type = core.get(m, selected)
    end
    return util["stream-into-empty-buffer"](openai, prompts(prompt_type), core.str("runbook-", core.get(m, selected), ".md"))
  end
  return vim.ui.select(core.keys(m), {prompt = "Select prompt type"}, _19_)
end
_2amodule_2a["generate-runbook"] = generate_runbook
--[[ (prompt-types) (prompts "github:docker/labs-make-runbook?ref=main&path=prompts/docker") (generate-runbook nil) ]]
nvim.create_user_command("GenerateRunbook", generate_runbook, {desc = "Generate a Runbook"})
return _2amodule_2a