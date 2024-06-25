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
local core, curl, fs, nvim, str, util = autoload("aniseed.core"), autoload("plenary.curl"), autoload("aniseed.fs"), autoload("aniseed.nvim"), autoload("aniseed.string"), autoload("slim.nvim")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["curl"] = curl
_2amodule_locals_2a["fs"] = fs
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
    local _18_ = core.slurp(vim.fn.printf("%s/.open-api-key", os.getenv("HOME")))
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
local function prompt_runner(args, callback)
  local function _34_(err, data)
    return callback(data)
  end
  local function _35_(err, data)
    return callback(data)
  end
  local function _38_(_36_)
    local _arg_37_ = _36_
    local code = _arg_37_["code"]
    local signal = _arg_37_["signal"]
    local data = _arg_37_
  end
  return vim.system(args, {text = true, stdout = _34_, stderr = _35_, stdin = false}, _38_)
end
_2amodule_2a["prompt-runner"] = prompt_runner
local function execute_prompt(type)
  local function _39_(callback)
    return prompt_runner({"docker", "run", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock", "--mount", "type=volume,source=docker-prompts,target=/prompts", "--mount", string.format("type=bind,source=%s,target=/project", vim.fn.getcwd()), "--mount", "type=bind,source=/Users/slim/.openai-api-key,target=/root/.openai-api-key", "vonwig/prompts:latest", "run", vim.fn.getcwd(), "jimclark106", "darwin", type}, callback)
  end
  return util["start-streaming"](_39_)
end
_2amodule_2a["execute-prompt"] = execute_prompt
local function prompt_run()
  local prompts = {"github:docker/labs-githooks?ref=main&path=prompts/git_hooks_just_llm", "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_with_linguist", "github:docker/labs-githooks?ref=main&path=prompts/git_hooks", "github:docker/labs-githooks?ref=main&path=prompts/git_hooks_single_step"}
  local function _40_(selected, _)
    local prompt = vim.fn.input("Prompt: ")
    return execute_prompt(selected)
  end
  return vim.ui.select(prompts, {prompt = "Select LLM"}, _40_)
end
_2amodule_2a["prompt-run"] = prompt_run
local promptRun = prompt_run
_2amodule_2a["promptRun"] = promptRun
--[[ (prompt-run) ]]
nvim.set_keymap("n", "<leader>assist", ":lua require('runbooks').promptRun()<CR>", {})
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
  local function _41_(_, chunk, _0)
    local function _42_(...)
      local _43_ = ...
      if (nil ~= _43_) then
        local s = _43_
        local function _44_(...)
          local _45_ = ...
          if (nil ~= _45_) then
            local s0 = _45_
            local function _46_(...)
              local _47_, _48_ = ...
              if ((_47_ == true) and (nil ~= _48_)) then
                local obj = _48_
                return core.first(obj.choices).delta.content
              elseif (nil ~= _47_) then
                local s1 = _47_
                return s1
              else
                return nil
              end
            end
            local function _50_()
              return vim.json.decode(s0)
            end
            return _46_(pcall(_50_))
          elseif (nil ~= _45_) then
            local s0 = _45_
            return s0
          else
            return nil
          end
        end
        local function _52_(...)
          if vim.startswith(s, "data:") then
            return s:sub(7)
          else
            return nil
          end
        end
        return _44_(_52_(...))
      elseif (nil ~= _43_) then
        local s = _43_
        return s
      else
        return nil
      end
    end
    return cb(_42_(chunk))
  end
  return curl.post("https://api.openai.com/v1/chat/completions", {body = vim.json.encode({model = "gpt-4", messages = messages, stream = true}), headers = {Authorization = core.str("Bearer ", opena_api_key()), ["Content-Type"] = "application/json"}, stream = _41_})
end
_2amodule_2a["openai"] = openai
--[[ (util.stream-into-empty-buffer openai (prompts "docker")) (openai (prompts "docker") (fn [s] (core.println s))) ]]
local function generate_friendly_prompt_name(prompt_type)
  local _54_ = parse_git_ref(prompt_type)
  if ((_G.type(_54_) == "table") and (nil ~= (_54_).repo) and (nil ~= (_54_).path)) then
    local repo = (_54_).repo
    local path = (_54_).path
    return string.format("runbook.gh-%s-%s.md", repo, string.gsub(path, "/", "-"))
  elseif ((_G.type(_54_) == "table") and (nil ~= (_54_).repo)) then
    local repo = (_54_).repo
    return vim.fn.printf("runbook.gh-%s.md", repo)
  elseif true then
    local _ = _54_
    return vim.fn.printf("runbook.%s.md", prompt_type)
  else
    return nil
  end
end
_2amodule_2a["generate-friendly-prompt-name"] = generate_friendly_prompt_name
--[[ (generate-friendly-prompt-name "github:docker/labs-make-runbook?ref=main&path=prompts/docker") (generate-friendly-prompt-name "whatever") ]]
local function generate_runbook()
  local m = core.assoc(prompt_types(), "custom", "custom")
  local function _56_(selected, _)
    local prompt_type
    if (selected == "custom") then
      prompt_type = vim.fn.input("prompt github ref: ")
    else
      prompt_type = core.get(m, selected)
    end
    return util["stream-into-empty-buffer"](openai, prompts(prompt_type), generate_friendly_prompt_name(core.get(m, selected)))
  end
  return vim.ui.select(core.keys(m), {prompt = "Select prompt type"}, _56_)
end
_2amodule_2a["generate-runbook"] = generate_runbook
--[[ (prompt-types) (prompts "github:docker/labs-make-runbook?ref=main&path=prompts/docker") (generate-runbook) ]]
local function _58_(_)
  local _59_, _60_ = pcall(generate_runbook)
  if ((_59_ == true) and true) then
    local _0 = _60_
    return core.println("GenerateRunbook completed")
  elseif ((_59_ == false) and (nil ~= _60_)) then
    local error = _60_
    return core.println(vim.fn.printf("GenerateRunbook failed to run: %s", error))
  else
    return nil
  end
end
nvim.create_user_command("GenerateRunbook", _58_, {desc = "Generate a Runbook"})
local function _64_(_62_)
  local _arg_63_ = _62_
  local args = _arg_63_["args"]
  local _65_, _66_ = pcall(register_runbook_type, args)
  if ((_65_ == true) and true) then
    local _ = _66_
    return core.println("RunbookRegister successful")
  elseif ((_65_ == false) and (nil ~= _66_)) then
    local error = _66_
    return core.println(vim.fn.printf("RunbookRegister failed to run: %s", error))
  else
    return nil
  end
end
nvim.create_user_command("RunbookRegister", _64_, {desc = "Register a Runbook", nargs = 1})
local function _70_(_68_)
  local _arg_69_ = _68_
  local args = _arg_69_["args"]
  local _71_, _72_ = pcall(unregister_runbook_type, args)
  if ((_71_ == true) and true) then
    local _ = _72_
    return core.println("RunbookUnregister successful")
  elseif ((_71_ == false) and (nil ~= _72_)) then
    local error = _72_
    return core.println(vim.fn.printf("RunbookUnregister failed to run: %s", error))
  else
    return nil
  end
end
nvim.create_user_command("RunbookUnregister", _70_, {desc = "Unregister a Runbook", nargs = 1})
return _2amodule_2a