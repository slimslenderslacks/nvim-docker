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
local core, curl, fs, jsonrpc, nvim, str, util = autoload("aniseed.core"), autoload("plenary.curl"), autoload("aniseed.fs"), autoload("jsonrpc"), autoload("aniseed.nvim"), autoload("aniseed.string"), autoload("slim.nvim")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["curl"] = curl
_2amodule_locals_2a["fs"] = fs
_2amodule_locals_2a["jsonrpc"] = jsonrpc
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["str"] = str
_2amodule_locals_2a["util"] = util
local function parse_git_ref(s)
  local function _1_(...)
    local _2_ = ...
    if (nil ~= _2_) then
      local s0 = _2_
      local function _3_(...)
        local _4_ = ...
        if ((_G.type(_4_) == "table") and (nil ~= (_4_)[1]) and true) then
          local ref = (_4_)[1]
          local _3fopts = (_4_)[2]
          local function _5_(...)
            local _6_ = ...
            if ((_G.type(_6_) == "table") and (nil ~= (_6_)[1]) and true) then
              local m = (_6_)[1]
              local _3fopts0 = (_6_)[2]
              if _3fopts0 then
                local function _7_(agg, s1)
                  local _let_8_ = vim.split(s1, "=")
                  local k = _let_8_[1]
                  local v = _let_8_[2]
                  return core.assoc(agg, k, v)
                end
                return core.reduce(_7_, m, vim.split(_3fopts0, "&"))
              else
                return m
              end
            elseif true then
              local __73_auto = _6_
              return ...
            else
              return nil
            end
          end
          local function _13_(...)
            local _11_, _12_ = string.match(ref, "github:(%S+)/(%S+)")
            if ((nil ~= _11_) and (nil ~= _12_)) then
              local owner = _11_
              local repo = _12_
              return {{owner = owner, repo = repo}, _3fopts}
            else
              return nil
            end
          end
          return _5_(_13_(...))
        elseif true then
          local __73_auto = _4_
          return ...
        else
          return nil
        end
      end
      return _3_(vim.split(s0, "?"))
    elseif true then
      local __73_auto = _2_
      return ...
    else
      return nil
    end
  end
  return _1_(s)
end
_2amodule_2a["parse-git-ref"] = parse_git_ref
--[[ (parse-git-ref "github:docker/labs-make-runbook?ref=main&path=prompts/docker") (parse-git-ref "github:docker/labs-make-runbook") (parse-git-ref "alskfj") ]]
local function opena_api_key()
  local function _17_()
    local _18_ = core.slurp(vim.fn.printf("%s/.openai-api-key", os.getenv("HOME")))
    if (nil ~= _18_) then
      local s = _18_
      return str.trim(s)
    else
      return nil
    end
  end
  return (_17_() or os.getenv("OPENAI_API_KEY") or error("unable to lookup OPENAI_API_KEY or read from $HOME/.open-api-key"))
end
_2amodule_2a["opena-api-key"] = opena_api_key
local function docker_run(args)
  local function _20_(...)
    local _21_, _22_ = ...
    if ((_21_ == true) and (nil ~= _22_)) then
      local obj = _22_
      local function _23_(...)
        local _24_, _25_ = ...
        if (nil ~= _24_) then
          local v = _24_
          local _26_ = v
          if ((_G.type(_26_) == "table") and ((_26_).code == 0) and (nil ~= (_26_).stdout)) then
            local out = (_26_).stdout
            return vim.json.decode(out)
          elseif ((_G.type(_26_) == "table") and (nil ~= (_26_).code)) then
            local code = (_26_).code
            return error(vim.fn.printf("docker exited with code %d", code))
          elseif ((_G.type(_26_) == "table") and (nil ~= (_26_).signal)) then
            local signal = (_26_).signal
            return error(vim.fn.printf("docker process was killed by signal %d", signal))
          else
            return nil
          end
        elseif ((_24_ == false) and (nil ~= _25_)) then
          local e = _25_
          return error("docker could not be executed")
        else
          return nil
        end
      end
      return _23_(obj.wait(obj))
    elseif ((_21_ == false) and (nil ~= _22_)) then
      local e = _22_
      return error("docker could not be executed")
    else
      return nil
    end
  end
  local function _30_()
    return vim.system(args, {text = true})
  end
  return _20_(pcall(_30_))
end
_2amodule_2a["docker-run"] = docker_run
local function prompt_types()
  local function _33_(agg, _31_)
    local _arg_32_ = _31_
    local title = _arg_32_["title"]
    local type = _arg_32_["type"]
    return core.assoc(agg, title, type)
  end
  return core.reduce(_33_, {}, docker_run({"docker", "run", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock", "--mount", "type=volume,source=docker-prompts,target=/prompts", "vonwig/prompts:latest", "prompts"}))
end
_2amodule_2a["prompt-types"] = prompt_types
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
  local function _34_(_, chunk, _0)
    local function _35_(...)
      local _36_ = ...
      if (nil ~= _36_) then
        local s = _36_
        local function _37_(...)
          local _38_ = ...
          if (nil ~= _38_) then
            local s0 = _38_
            local function _39_(...)
              local _40_, _41_ = ...
              if ((_40_ == true) and (nil ~= _41_)) then
                local obj = _41_
                return core.first(obj.choices).delta.content
              elseif (nil ~= _40_) then
                local s1 = _40_
                return s1
              else
                return nil
              end
            end
            local function _43_()
              return vim.json.decode(s0)
            end
            return _39_(pcall(_43_))
          elseif (nil ~= _38_) then
            local s0 = _38_
            return s0
          else
            return nil
          end
        end
        local function _45_(...)
          if vim.startswith(s, "data:") then
            return s:sub(7)
          else
            return nil
          end
        end
        return _37_(_45_(...))
      elseif (nil ~= _36_) then
        local s = _36_
        return s
      else
        return nil
      end
    end
    return cb(_35_(chunk))
  end
  return curl.post("https://api.openai.com/v1/chat/completions", {body = vim.json.encode({model = "gpt-4", messages = messages, stream = true}), headers = {Authorization = core.str("Bearer ", opena_api_key()), ["Content-Type"] = "application/json"}, stream = _34_})
end
_2amodule_2a["openai"] = openai
--[[ (util.stream-into-empty-buffer openai (prompts "docker")) (openai (prompts "docker") (fn [s] (core.println s))) ]]
local function generate_friendly_prompt_name(prompt_type)
  local _47_ = parse_git_ref(prompt_type)
  if ((_G.type(_47_) == "table") and (nil ~= (_47_).repo) and (nil ~= (_47_).path)) then
    local repo = (_47_).repo
    local path = (_47_).path
    return string.format("runbook.gh-%s-%s.md", repo, string.gsub(path, "/", "-"))
  elseif ((_G.type(_47_) == "table") and (nil ~= (_47_).repo)) then
    local repo = (_47_).repo
    return vim.fn.printf("runbook.gh-%s.md", repo)
  elseif true then
    local _ = _47_
    return vim.fn.printf("runbook.%s.md", prompt_type)
  else
    return nil
  end
end
_2amodule_2a["generate-friendly-prompt-name"] = generate_friendly_prompt_name
--[[ (generate-friendly-prompt-name "github:docker/labs-make-runbook?ref=main&path=prompts/docker") (generate-friendly-prompt-name "whatever") ]]
local function generate_runbook()
  local m = core.assoc(prompt_types(), "custom", "custom")
  local function _49_(selected, _)
    local prompt_type
    if (selected == "custom") then
      prompt_type = vim.fn.input("prompt github ref: ")
    else
      prompt_type = core.get(m, selected)
    end
    return util["stream-into-empty-buffer"](openai, prompts(prompt_type), generate_friendly_prompt_name(core.get(m, selected)))
  end
  return vim.ui.select(core.keys(m), {prompt = "Select prompt type"}, _49_)
end
_2amodule_2a["generate-runbook"] = generate_runbook
--[[ (prompt-types) (prompts "github:docker/labs-make-runbook?ref=main&path=prompts/docker") (generate-runbook) ]]
local function _51_(_)
  local _52_, _53_ = pcall(generate_runbook)
  if ((_52_ == true) and true) then
    local _0 = _53_
    return core.println("GenerateRunbook completed")
  elseif ((_52_ == false) and (nil ~= _53_)) then
    local error = _53_
    return core.println(vim.fn.printf("GenerateRunbook failed to run: %s", error))
  else
    return nil
  end
end
nvim.create_user_command("GenerateRunbook", _51_, {desc = "Generate a Runbook"})
local function _57_(_55_)
  local _arg_56_ = _55_
  local args = _arg_56_["args"]
  local _58_, _59_ = pcall(register_runbook_type, args)
  if ((_58_ == true) and true) then
    local _ = _59_
    return core.println("RunbookRegister successful")
  elseif ((_58_ == false) and (nil ~= _59_)) then
    local error = _59_
    return core.println(vim.fn.printf("RunbookRegister failed to run: %s", error))
  else
    return nil
  end
end
nvim.create_user_command("RunbookRegister", _57_, {desc = "Register a Runbook", nargs = 1})
local function _63_(_61_)
  local _arg_62_ = _61_
  local args = _arg_62_["args"]
  local _64_, _65_ = pcall(unregister_runbook_type, args)
  if ((_64_ == true) and true) then
    local _ = _65_
    return core.println("RunbookUnregister successful")
  elseif ((_64_ == false) and (nil ~= _65_)) then
    local error = _65_
    return core.println(vim.fn.printf("RunbookUnregister failed to run: %s", error))
  else
    return nil
  end
end
nvim.create_user_command("RunbookUnregister", _63_, {desc = "Unregister a Runbook", nargs = 1})
return _2amodule_2a