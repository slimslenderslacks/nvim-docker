local _2afile_2a = "fnl/slim/nvim.fnl"
local _2amodule_name_2a = "slim.nvim"
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
local core, lspconfig_util, nvim, str = autoload("aniseed.core"), autoload("lspconfig.util"), autoload("aniseed.nvim"), autoload("aniseed.string")
do end (_2amodule_locals_2a)["core"] = core
_2amodule_locals_2a["lspconfig-util"] = lspconfig_util
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["str"] = str
local function decode_payload(s)
  return vim.json.decode(vim.base64.decode(((vim.split(s, ".", {plain = true}))[2] .. "=")))
end
_2amodule_2a["decode-payload"] = decode_payload
local function update_buf(buf, lines)
  local function _1_()
    vim.cmd("norm! G")
    return vim.api.nvim_put(lines, "", true, true)
  end
  return vim.api.nvim_buf_call(buf, _1_)
end
_2amodule_2a["update-buf"] = update_buf
local function git_root()
  return (lspconfig_util.root_pattern(".git")(vim.fn.getcwd()) or vim.fn.getcwd())
end
_2amodule_2a["git-root"] = git_root
local function get_current_buffer_selection()
  local _let_2_ = nvim.fn.getpos("'<")
  local _ = _let_2_[1]
  local s1 = _let_2_[2]
  local e1 = _let_2_[3]
  local _0 = _let_2_[4]
  local _let_3_ = nvim.fn.getpos("'>")
  local _1 = _let_3_[1]
  local s2 = _let_3_[2]
  local e2 = _let_3_[3]
  local _2 = _let_3_[4]
  return nvim.buf_get_text(nvim.buf.nr(), (s1 - 1), (e1 - 1), (s2 - 1), (e2 - 1), {})
end
_2amodule_2a["get-current-buffer-selection"] = get_current_buffer_selection
local win_opts = {relative = "editor", row = 3, col = 3, width = 80, height = 35, style = "minimal", border = "rounded", title = "my title", title_pos = "center"}
_2amodule_2a["win-opts"] = win_opts
local function open_win(buf, opts)
  local win = nvim.open_win(buf, true, core.merge(win_opts, opts))
  nvim.set_option_value("filetype", "markdown", {buf = buf})
  nvim.set_option_value("buftype", "nofile", {buf = buf})
  nvim.set_option_value("wrap", true, {win = win})
  nvim.set_option_value("linebreak", true, {win = win})
  return win
end
_2amodule_2a["open-win"] = open_win
local function show_spinner(buf, n)
  local current_char = 1
  local characters = {"\226\160\139", "\226\160\153", "\226\160\185", "\226\160\184", "\226\160\188", "\226\160\180", "\226\160\166", "\226\160\167", "\226\160\135", "\226\160\143"}
  local format = "> Generating %s"
  local t = vim.loop.new_timer()
  local function _4_()
    local lines = {format:format(core.get(characters, current_char))}
    nvim.buf_set_lines(buf, n, (n + 1), false, lines)
    current_char = ((current_char % core.count(characters)) + 1)
    return nil
  end
  t:start(100, 100, vim.schedule_wrap(_4_))
  return t
end
_2amodule_2a["show-spinner"] = show_spinner
local function uuid()
  local p = vim.system({"uuidgen"}, {text = true})
  local obj = p:wait()
  return str.trim(obj.stdout)
end
_2amodule_2a["uuid"] = uuid
local function open(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  nvim.buf_set_text(buf, 0, 0, 0, 0, lines)
  return {open_win(buf, {title = "Copilot"}), buf}
end
_2amodule_2a["open"] = open
local function open_new_buffer(s)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_win_set_buf(0, buf)
  local function _5_()
    return vim.api.nvim_buf_set_name(buf, s)
  end
  pcall(_5_)
  vim.api.nvim_command("set filetype=markdown")
  return buf
end
_2amodule_2a["open-new-buffer"] = open_new_buffer
--[[ (open-new-buffer "runbook-docker.md") ]]
local function start_streaming(stream_generator)
  local tokens = {}
  local buf = open_new_buffer("chat")
  local t = show_spinner(buf, 1)
  nvim.buf_set_lines(buf, -1, -1, false, {"", ""})
  local function _6_(s)
    local function _7_()
      t:stop()
      tokens = core.concat(tokens, {s})
      return vim.api.nvim_buf_set_lines(buf, 1, -1, false, str.split(str.join(tokens), "\n"))
    end
    return vim.schedule(_7_)
  end
  return stream_generator(_6_)
end
_2amodule_2a["start-streaming"] = start_streaming
local function stream_into_buffer(stream_generator, prompt)
  local tokens = {}
  local lines = str.split(prompt, "\n")
  local _let_8_ = open(lines)
  local win = _let_8_[1]
  local buf = _let_8_[2]
  local t = show_spinner(buf, core.inc(core.count(lines)))
  nvim.buf_set_lines(buf, -1, -1, false, {"", ""})
  local function _9_(s)
    local function _10_()
      t:stop()
      tokens = core.concat(tokens, {s})
      return vim.api.nvim_buf_set_lines(buf, core.inc(core.count(lines)), -1, false, str.split(str.join(tokens), "\n"))
    end
    return vim.schedule(_10_)
  end
  return stream_generator(prompt, _9_)
end
_2amodule_2a["stream-into-buffer"] = stream_into_buffer
local function stream_into_empty_buffer(stream_generator, prompt, buffer_name)
  local tokens = {}
  local buf = open_new_buffer(buffer_name)
  nvim.buf_set_lines(buf, -1, -1, false, {"", ""})
  local function _11_(s)
    tokens = core.concat(tokens, {s})
    local lines = str.split(str.join(tokens), "\n")
    local function _12_()
      return vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    end
    return vim.schedule(_12_)
  end
  return stream_generator(prompt, _11_)
end
_2amodule_2a["stream-into-empty-buffer"] = stream_into_empty_buffer
local function open_file(path)
  local win = vim.api.nvim_tabpage_get_win(0)
  vim.cmd("vsplit")
  vim.cmd(("e " .. path))
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_current_win(win)
  return buf
end
_2amodule_2a["open-file"] = open_file
local function append(buf, lines)
  return vim.api.nvim_buf_set_lines(buf, core.count(vim.api.nvim_buf_get_lines(buf, 0, -1, false)), -1, false, lines)
end
_2amodule_2a["append"] = append
--[[ (def buf (open-file "Dockerfile.test")) (append buf ["yo"]) (let [buf (nvim.create_buf false true)] (open-win buf {:title "hey"}) (show-spinner buf)) ]]
return _2amodule_2a