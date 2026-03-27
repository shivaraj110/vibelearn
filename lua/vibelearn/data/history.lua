local M = {}
local Path = require("plenary.path")
local log = require("vibelearn.utils.logger")

M.history_file = nil
M.history = nil

M.init = function(data_path)
  M.history_file = Path:new(data_path, "history.json")
  
  -- Create data directory if it doesn't exist
  if not M.history_file:exists() then
    local data_dir = Path:new(data_path)
    if not data_dir:exists() then
      data_dir:mkdir({ parents = true })
    end
  end
  
  M.history = M.load()
end

M.load = function()
  if not M.history_file or not M.history_file:exists() then
    return M.create_default()
  end
  
  local ok, data = pcall(function()
    local content = M.history_file:read()
    return vim.json.decode(content)
  end)
  
  if not ok or not data then
    log.warn("Failed to load history, creating new one")
    return M.create_default()
  end
  
  return data
end

M.create_default = function()
  return {
    version = 1,
    activities = {},
    sessions = {},
    language_switches = {},
    error_patterns = {},
    git_commits = {},
  }
end

M.save = function()
  if not M.history_file then
    log.error("History not initialized")
    return false
  end
  
  local ok, encoded = pcall(vim.json.encode, M.history)
  if not ok then
    log.error("Failed to encode history")
    return false
  end
  
  M.history_file:write(encoded, "w")
  return true
end

return M