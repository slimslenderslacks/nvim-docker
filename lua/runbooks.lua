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
local function opena_api_key()
  local function _1_()
    local _2_ = core.slurp(vim.fn.printf("%s/.open-api-key", os.getenv("HOME")))
    if (nil ~= _2_) then
      local s = _2_
      return string.trim(s)
    else
      return nil
    end
  end
  return (_1_() or os.getenv("OPENAI_API_KEY") or error("unable to lookup OPENAI_API_KEY or read from $HOME/.open-api-key"))
end
_2amodule_2a["opena-api-key"] = opena_api_key
local function docker_run(args)
  local function _4_(...)
    local _5_, _6_ = ...
    if ((_5_ == true) and (nil ~= _6_)) then
      local obj = _6_
      local function _7_(...)
        local _8_, _9_ = ...
        if (nil ~= _8_) then
          local v = _8_
          local _10_ = v
          if ((_G.type(_10_) == "table") and ((_10_).code == 0) and (nil ~= (_10_).stdout)) then
            local out = (_10_).stdout
            return vim.json.decode(out)
          elseif ((_G.type(_10_) == "table") and (nil ~= (_10_).code)) then
            local code = (_10_).code
            return error(vim.fn.printf("docker exited with code %d", code))
          elseif ((_G.type(_10_) == "table") and (nil ~= (_10_).signal)) then
            local signal = (_10_).signal
            return error(vim.fn.printf("docker process was killed by signal %d", signal))
          else
            return nil
          end
        elseif ((_8_ == false) and (nil ~= _9_)) then
          local e = _9_
          return error("docker could not be executed")
        else
          return nil
        end
      end
      return _7_(obj.wait(obj))
    elseif ((_5_ == false) and (nil ~= _6_)) then
      local e = _6_
      return error("docker could not be executed")
    else
      return nil
    end
  end
  local function _14_()
    return vim.system(args, {text = true})
  end
  return _4_(pcall(_14_))
end
_2amodule_2a["docker-run"] = docker_run
local function prompt_types()
  local function _17_(agg, _15_)
    local _arg_16_ = _15_
    local title = _arg_16_["title"]
    local type = _arg_16_["type"]
    return core.assoc(agg, title, type)
  end
  return core.reduce(_17_, {}, docker_run({"docker", "run", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock", "--mount", "type=volume,source=docker-prompts,target=/prompts", "vonwig/prompts:latest", "prompts"}))
end
_2amodule_2a["prompt-types"] = prompt_types
--[[ (prompt-types) ]]
local function register_runbook_type(t)
  return docker_run({"docker", "run", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock", "--mount", "type=volume,source=docker-prompts,target=/prompts", "vonwig/prompts:latest", "register", t})
end
_2amodule_2a["register-runbook-type"] = register_runbook_type
local function unregister_runbook_type(t)
  return docker_run({"docker", "run", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock", "--mount", "type=volume,source=docker-prompts,target=/prompts", "vonwig/prompts:latest", "unregister", t})
end
_2amodule_2a["unregister-runbook-type"] = unregister_runbook_type
local function prompts(type)
  return docker_run({"docker", "run", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock", "--mount", "type=volume,source=docker-prompts,target=/prompts", "vonwig/prompts:latest", vim.fn.getcwd(), "jimclark106", "darwin", type})
end
_2amodule_2a["prompts"] = prompts
--[[ (prompts "docker") ]]
local function openai(messages, cb)
  local function _18_(_, chunk, _0)
    local function _19_(...)
      local _20_ = ...
      if (nil ~= _20_) then
        local s = _20_
        local function _21_(...)
          local _22_ = ...
          if (nil ~= _22_) then
            local s0 = _22_
            local function _23_(...)
              local _24_, _25_ = ...
              if ((_24_ == true) and (nil ~= _25_)) then
                local obj = _25_
                return core.first(obj.choices).delta.content
              elseif (nil ~= _24_) then
                local s1 = _24_
                return s1
              else
                return nil
              end
            end
            local function _27_()
              return vim.json.decode(s0)
            end
            return _23_(pcall(_27_))
          elseif (nil ~= _22_) then
            local s0 = _22_
            return s0
          else
            return nil
          end
        end
        local function _29_(...)
          if vim.startswith(s, "data:") then
            return s:sub(7)
          else
            return nil
          end
        end
        return _21_(_29_(...))
      elseif (nil ~= _20_) then
        local s = _20_
        return s
      else
        return nil
      end
    end
    return cb(_19_(chunk))
  end
  return curl.post("https://api.openai.com/v1/chat/completions", {body = vim.json.encode({model = "gpt-4", messages = messages, stream = true}), headers = {Authorization = core.str("Bearer ", opena_api_key()), ["Content-Type"] = "application/json"}, stream = _18_})
end
_2amodule_2a["openai"] = openai
--[[ (util.stream-into-empty-buffer openai (prompts "docker")) (openai (prompts "docker") (fn [s] (core.println s))) ]]
local function generate_runbook()
  local m = core.assoc(prompt_types(), "custom", "custom")
  local function _31_(selected, _)
    local prompt_type
    if (selected == "custom") then
      prompt_type = vim.fn.input("prompt github ref: ")
    else
      prompt_type = core.get(m, selected)
    end
    return util["stream-into-empty-buffer"](openai, prompts(prompt_type), core.str("runbook-", core.get(m, selected), ".md"))
  end
  return vim.ui.select(core.keys(m), {prompt = "Select prompt type"}, _31_)
end
_2amodule_2a["generate-runbook"] = generate_runbook
--[[ (prompt-types) (prompts "github:docker/labs-make-runbook?ref=main&path=prompts/docker") (generate-runbook) ]]
local function _33_(_)
  local _34_, _35_ = pcall(generate_runbook)
  if ((_34_ == true) and true) then
    local _0 = _35_
    return core.println("GenerateRunbook completed")
  elseif ((_34_ == false) and (nil ~= _35_)) then
    local error = _35_
    return core.println(vim.fn.printf("GenerateRunbook failed to run: %s", error))
  else
    return nil
  end
end
nvim.create_user_command("GenerateRunbook", _33_, {desc = "Generate a Runbook"})
local function _39_(_37_)
  local _arg_38_ = _37_
  local args = _arg_38_["args"]
  local _40_, _41_ = pcall(register_runbook_type, args)
  if ((_40_ == true) and true) then
    local _ = _41_
    return core.println("RunbookRegister successful")
  elseif ((_40_ == false) and (nil ~= _41_)) then
    local error = _41_
    return core.println(vim.fn.printf("RunbookRegister failed to run: %s", error))
  else
    return nil
  end
end
nvim.create_user_command("RunbookRegister", _39_, {desc = "Register a Runbook", nargs = 1})
local function _45_(_43_)
  local _arg_44_ = _43_
  local args = _arg_44_["args"]
  local _46_, _47_ = pcall(unregister_runbook_type, args)
  if ((_46_ == true) and true) then
    local _ = _47_
    return core.println("RunbookUnregister successful")
  elseif ((_46_ == false) and (nil ~= _47_)) then
    local error = _47_
    return core.println(vim.fn.printf("RunbookUnregister failed to run: %s", error))
  else
    return nil
  end
end
nvim.create_user_command("RunbookUnregister", _45_, {desc = "Unregister a Runbook", nargs = 1})
return _2amodule_2a