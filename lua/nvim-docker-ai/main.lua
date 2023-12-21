local _2afile_2a = "fnl/nvim-docker-ai/main.fnl"
local _2amodule_name_2a = "nvim-docker-ai.main"
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
local core, dockerai, filetypes, nano_copilot = require("nvim-docker-ai.aniseed.core"), require("dockerai"), require("filetypes"), require("nano-copilot")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["dockerai"] = dockerai
_2amodule_locals_2a["filetypes"] = filetypes
_2amodule_locals_2a["nano-copilot"] = nano_copilot
local function init()
  core.println("initialize docker ai")
  return filetypes.init()
end
_2amodule_2a["init"] = init
return _2amodule_2a