local _2afile_2a = "fnl/complaints.fnl"
local _2amodule_name_2a = "complaints"
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
local core, lsps, nvim, string, util = autoload("aniseed.core"), autoload("lsps"), autoload("aniseed.nvim"), autoload("aniseed.string"), autoload("slim.nvim")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["lsps"] = lsps
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["string"] = string
_2amodule_locals_2a["util"] = util
local function complain(_1_)
  local _arg_2_ = _1_
  local path = _arg_2_["path"]
  local language_id = _arg_2_["languageId"]
  local start_line = _arg_2_["startLine"]
  local end_line = _arg_2_["endLine"]
  local edit = _arg_2_["edit"]
  local reason = _arg_2_["reason"]
  local args = _arg_2_
  core.println(complain, args)
  local docker_lsp = lsps["get-client-by-name"]("docker_lsp")
  local params
  local _3_
  if end_line then
    _3_ = (end_line - 1)
  else
    _3_ = (start_line - 1)
  end
  params = {uri = {external = ("file://" .. path)}, message = reason, range = {start = {line = core.dec(start_line), character = 0}, ["end"] = {line = _3_, character = -1}}, edit = edit}
  local function _5_(err, result, ctx, config)
  end
  return docker_lsp.request("docker/complain", params, _5_)
end
_2amodule_2a["complain"] = complain
return _2amodule_2a