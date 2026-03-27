local M = {}

M.levels = {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

M.config = {
  level = M.levels.INFO,
  use_notify = true,
  notify_level = M.levels.WARN,
}

M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

M.log = function(level, msg, ...)
  if level < M.config.level then
    return
  end
  
  local args = { ... }
  local formatted_msg = msg
  
  if #args > 0 then
    local ok, result = pcall(string.format, msg, unpack(args))
    if ok then
      formatted_msg = result
    end
  end
  
  local level_names = { "DEBUG", "INFO", "WARN", "ERROR" }
  local level_name = level_names[level + 1] or "UNKNOWN"
  
  local log_entry = string.format("[VibeLearn][%s] %s", level_name, formatted_msg)
  
  if M.config.use_notify and level >= M.config.notify_level then
    local notify_levels = {
      [M.levels.DEBUG] = vim.log.levels.DEBUG,
      [M.levels.INFO] = vim.log.levels.INFO,
      [M.levels.WARN] = vim.log.levels.WARN,
      [M.levels.ERROR] = vim.log.levels.ERROR,
    }
    vim.notify(log_entry, notify_levels[level] or vim.log.levels.INFO)
  end
  
  local log_file = vim.fn.stdpath("data") .. "/vibelearn/vibelearn.log"
  local ok, f = pcall(io.open, log_file, "a")
  if ok and f then
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    f:write(string.format("%s %s\n", timestamp, log_entry))
    f:close()
  end
end

M.debug = function(msg, ...)
  M.log(M.levels.DEBUG, msg, ...)
end

M.info = function(msg, ...)
  M.log(M.levels.INFO, msg, ...)
end

M.warn = function(msg, ...)
  M.log(M.levels.WARN, msg, ...)
end

M.error = function(msg, ...)
  M.log(M.levels.ERROR, msg, ...)
end

return M