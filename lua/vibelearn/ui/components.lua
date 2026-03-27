local M = {}
local NuiText = require("nui.text")
local NuiLine = require("nui.line")

M.tokenize = function(text, highlight_groups)
  local tokens = {}
  local current = ""
  local current_group = nil
  
  for word in text:gmatch("%S+") do
    local group = highlight_groups[word] or "Normal"
    if group ~= current_group then
      if current ~= "" then
        table.insert(tokens, { text = current, group = current_group })
      end
      current = word .. " "
      current_group = group
    else
      current = current .. word .. " "
    end
  end
  
  if current ~= "" then
    table.insert(tokens, { text = current, group = current_group })
  end
  
  return tokens
end

M.create_line = function(items)
  local line = NuiLine()
  
  for _, item in ipairs(items) do
    if type(item) == "string" then
      line:append(item, "Normal")
    elseif type(item) == "table" then
      local text = item.text or item[1] or ""
      local group = item.group or item[2] or "Normal"
      line:append(text, group)
    end
  end
  
  return line
end

M.progress_bar = function(percentage, config)
  config = config or {}
  local width = config.width or 20
  local filled_char = config.filled_char or "█"
  local empty_char = config.empty_char or "░"
  local show_percentage = config.show_percentage ~= false
  
  local filled = math.floor(percentage / 100 * width)
  local empty = width - filled
  
  local bar = "["
  for i = 1, filled do
    bar = bar .. filled_char
  end
  for i = 1, empty do
    bar = bar .. empty_char
  end
  bar = bar .. "]"
  
  if show_percentage then
    bar = string.format("%s %d%%", bar, percentage)
  end
  
  return bar
end

M.highlight = {}
M.highlight.Title = "Title"
M.highlight.Keyword = "Keyword"
M.highlight.String = "String"
M.highlight.Number = "Number"
M.highlight.Identifier = "Identifier"
M.highlight.Comment = "Comment"
M.highlight.Error = "Error"
M.highlight.Warning = "Warning"
M.highlight.Success = "String"
M.highlight.Info = "Directory"

M.text = function(text, group)
  return NuiText(text, group or "Normal")
end

M.line = function()
  return NuiLine()
end

M.format_list = function(items, config)
  config = config or {}
  local bullet = config.bullet or "•"
  local indent = config.indent or 2
  
  local lines = {}
  for _, item in ipairs(items) do
    local line = M.line()
    line:append(string.rep(" ", indent), "Normal")
    line:append(bullet .. " ", "Keyword")
    
    if type(item) == "string" then
      line:append(item, "Normal")
    elseif type(item) == "table" then
      for _, part in ipairs(item) do
        if type(part) == "string" then
          line:append(part, "Normal")
        else
          line:append(part.text, part.group or "Normal")
        end
      end
    end
    
    table.insert(lines, line)
  end
  
  return lines
end

M.format_table = function(data, config)
  config = config or {}
  local key_width = config.key_width or 20
  local separator = config.separator or ": "
  
  local lines = {}
  for key, value in pairs(data) do
    local line = M.line()
    
    local key_str = tostring(key)
    if #key_str < key_width then
      key_str = key_str .. string.rep(" ", key_width - #key_str)
    end
    
    line:append(key_str, "Keyword")
    line:append(separator, "Normal")
    line:append(tostring(value), "String")
    
    table.insert(lines, line)
  end
  
  return lines
end

M.center_text = function(text, width)
  width = width or vim.api.nvim_win_get_width(0)
  local text_len = #text
  local padding = math.floor((width - text_len) / 2)
  
  return string.rep(" ", padding) .. text
end

M.wrap_text = function(text, width)
  width = width or 80
  local lines = {}
  local current_line = ""
  
  for word in text:gmatch("%S+") do
    if #current_line + #word + 1 > width then
      table.insert(lines, current_line)
      current_line = word
    else
      if current_line ~= "" then
        current_line = current_line .. " "
      end
      current_line = current_line .. word
    end
  end
  
  if current_line ~= "" then
    table.insert(lines, current_line)
  end
  
  return lines
end

M.status = function(status_type)
  local statuses = {
    success = { text = "✔", group = "String" },
    error = { text = "✗", group = "Error" },
    warning = { text = "⚠", group = "Warning" },
    info = { text = "ℹ", group = "Directory" },
    pending = { text = "○", group = "Comment" },
    running = { text = "●", group = "Directory" },
  }
  
  return statuses[status_type] or statuses.pending
end

M.keybind = function(key, description, group)
  group = group or "Keyword"
  local line = M.line()
  line:append("[", "Normal")
  line:append(key, group)
  line:append("] ", "Normal")
  line:append(description, "String")
  return line
end

return M