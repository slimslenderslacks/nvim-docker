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
local commands, core, filetypes, lsps, nano_copilot = require("commands"), require("nvim-docker-ai.aniseed.core"), require("filetypes"), require("lsps"), require("nano-copilot")
do end (_2amodule_locals_2a)["commands"] = commands
_2amodule_locals_2a["core"] = core
_2amodule_locals_2a["filetypes"] = filetypes
_2amodule_locals_2a["lsps"] = lsps
_2amodule_locals_2a["nano-copilot"] = nano_copilot
local function init()
  return filetypes.init()
end
_2amodule_2a["init"] = init
local function after()
end
_2amodule_2a["after"] = after
return _2amodule_2a