local _2afile_2a = "fnl/jsonrpc.fnl"
local _2amodule_name_2a = "jsonrpc"
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
local core, nvim, str = autoload("aniseed.core"), autoload("aniseed.nvim"), autoload("aniseed.string")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["str"] = str
local function parse_message(s)
  local function _1_(...)
    local _2_, _3_, _4_, _5_, _6_, _7_ = ...
    if ((_2_ == true) and (nil ~= _3_) and (nil ~= _4_) and true and (nil ~= _6_) and (nil ~= _7_)) then
      local x = _3_
      local y = _4_
      local _ = _5_
      local content_length = _6_
      local json = _7_
      local function _8_(...)
        local _9_, _10_ = ...
        if (nil ~= _9_) then
          local json_string = _9_
          local function _11_(...)
            local _12_, _13_ = ...
            if ((_12_ == true) and (nil ~= _13_)) then
              local obj = _13_
              return obj
            elseif ((_12_ == false) and (nil ~= _13_)) then
              local err = _13_
              return {error = err, data = s}
            elseif true then
              local _0 = _12_
              return {error = "unknown", data = s}
            else
              return nil
            end
          end
          local function _15_()
            return vim.json.decode(json_string)
          end
          return _11_(pcall(_15_))
        elseif ((_9_ == false) and (nil ~= _10_)) then
          local err = _10_
          return {error = err, data = s}
        elseif true then
          local _0 = _9_
          return {error = "unknown", data = s}
        else
          return nil
        end
      end
      return _8_(string.sub(json, 1, tonumber(content_length)))
    elseif ((_2_ == false) and (nil ~= _3_)) then
      local err = _3_
      return {error = err, data = s}
    elseif true then
      local _ = _2_
      return {error = "unknown", data = s}
    else
      return nil
    end
  end
  local function _18_()
    return string.find(s, "(%S+): (%d+)\13\n\13\n(.*)")
  end
  return _1_(pcall(_18_))
end
_2amodule_2a["parse-message"] = parse_message
local function message_splitter(agg, s, n)
  local _19_, _20_ = string.find(s, "Content", n)
  if ((nil ~= _19_) and (nil ~= _20_)) then
    local start = _19_
    local _end = _20_
    return message_splitter(core.concat(agg, {start}), s, _end)
  elseif true then
    local _ = _19_
    return agg
  else
    return nil
  end
end
_2amodule_2a["message-splitter"] = message_splitter
local function message_iterator(s)
  local start_locations = message_splitter({}, s, 1)
  local index = 1
  local function _22_()
    local start = start_locations[index]
    local _end = start_locations[core.inc(index)]
    if (start and _end) then
      index = core.inc(index)
      return string.sub(s, start, core.dec(_end))
    elseif start then
      index = core.inc(index)
      return string.sub(s, start)
    else
      return nil
    end
  end
  return _22_
end
_2amodule_2a["message-iterator"] = message_iterator
local function messages(data)
  local tbl_17_auto = {}
  local i_18_auto = #tbl_17_auto
  for s in message_iterator(data) do
    local val_19_auto = parse_message(s)
    if (nil ~= val_19_auto) then
      i_18_auto = (i_18_auto + 1)
      do end (tbl_17_auto)[i_18_auto] = val_19_auto
    else
    end
  end
  return tbl_17_auto
end
_2amodule_2a["messages"] = messages
--[[ (message (core.slurp "hey.txt")) ]]
return _2amodule_2a