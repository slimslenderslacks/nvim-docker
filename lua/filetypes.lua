local _2afile_2a = "fnl/filetypes.fnl"
local _2amodule_name_2a = "filetypes"
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
local function init()
  vim.filetype.add({filename = {["compose.yaml"] = "dockercompose", [".dockerignore"] = "dockerignore"}})
  vim.filetype.add({extension = {shellscript = "shellscript"}})
  return vim.filetype.add({extension = {shellscript = "dockerai"}})
end
_2amodule_2a["init"] = init
return _2amodule_2a