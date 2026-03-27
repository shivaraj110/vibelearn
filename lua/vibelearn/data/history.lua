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

M.record_activity = function(activity_type, data)
  local activity = {
    type = activity_type,
    data = data or {},
    timestamp = os.time(),
    date = os.date("%Y-%m-%d"),
    time = os.date("%H:%M:%S"),
  }
  
  table.insert(M.history.activities,1, activity)
  
  local max_days = 30
  local cutoff_time = os.time() - (max_days * 24 * 60 * 60)
  
  M.history.activities = vim.tbl_filter(function(act)
    return act.timestamp > cutoff_time
  end, M.history.activities)
  
  M.save()
  return activity
end

M.record_filetype_switch = function(from_ft, to_ft)
  local switch = {
    from = from_ft,
    to = to_ft,
    timestamp = os.time(),
    buffer = vim.api.nvim_get_current_buf(),
    file = vim.api.nvim_buf_get_name(0),
  }
  
  table.insert(M.history.language_switches, 1, switch)
  
  if #M.history.language_switches > 1000 then
    table.remove(M.history.language_switches)
  end
  
  M.record_activity("filetype_switch", switch)
end

M.record_lsp_error = function(lang, error_type, message, file, line)
  local error_entry = {
    language = lang,
    type = error_type,
    message = message,
    file = file,
    line = line,
    timestamp = os.time(),
  }
  
  table.insert(M.history.error_patterns, 1, error_entry)
  
  if #M.history.error_patterns > 5000 then
    table.remove(M.history.error_patterns)
  end
  
  M.record_activity("lsp_error", error_entry)
end

M.record_git_commit = function(commit_hash, message, files_changed, insertions, deletions)
  local commit = {
    hash = commit_hash,
    message = message,
    files = files_changed,
    insertions = insertions,
    deletions = deletions,
    timestamp = os.time(),
  }
  
  table.insert(M.history.git_commits, 1, commit)
  
  if #M.history.git_commits > 1000 then
    table.remove(M.history.git_commits)
  end
  
  M.record_activity("git_commit", commit)
end

M.record_session = function(session_type, duration, metadata)
  local session = {
    type = session_type,
    duration_seconds = duration,
    metadata = metadata or {},
    start_time = os.time() - duration,
    end_time = os.time(),
  }
  
  table.insert(M.history.sessions, 1, session)
  
  if #M.history.sessions >500 then
    table.remove(M.history.sessions)
  end
  
  M.record_activity("session", session)
end

M.get_activities_by_type = function(activity_type, limit)
  local filtered = vim.tbl_filter(function(act)
    return act.type == activity_type
  end, M.history.activities or {})
  
  if limit then
    local result = {}
    for i = 1, math.min(limit, #filtered) do
      table.insert(result, filtered[i])
    end
    return result
  end
  
  return filtered
end

M.get_error_patterns = function(lang, limit)
  limit = limit or 10
  
  local errors = vim.tbl_filter(function(err)
    return err.language == lang
  end, M.history.error_patterns or {})
  
  local pattern_counts = {}
  for _, err in ipairs(errors) do
    local key = (err.type or "unknown") .. ":" .. (err.message or "")
    if not pattern_counts[key] then
      pattern_counts[key] = {
        type = err.type,
        message = err.message,
        count = 0,
        examples = {},
      }
    end
    pattern_counts[key].count = pattern_counts[key].count + 1
    
    if #pattern_counts[key].examples < 5 then
      table.insert(pattern_counts[key].examples, {
        file = err.file,
        line = err.line,
        timestamp = err.timestamp,
      })
    end
  end
  
  local sorted = {}
  for _, pattern in pairs(pattern_counts) do
    table.insert(sorted, pattern)
  end
  
  table.sort(sorted, function(a, b)
    return a.count > b.count
  end)
  
  local result = {}
  for i = 1, math.min(limit, #sorted) do
    table.insert(result, sorted[i])
  end
  
  return result
end

M.get_language_usage_stats = function(lang, days)
  days = days or 30
  local cutoff = os.time() - (days * 24 * 60 * 60)
  
  local switches = vim.tbl_filter(function(switch)
    return (switch.from == lang or switch.to == lang) and switch.timestamp > cutoff
  end, M.history.language_switches or {})
  
  local total_switches = #switches
  local time_spent = 0
  
  if #switches > 1 then
    for i = 1, #switches - 1 do
      time_spent = time_spent + (switches[i].timestamp - switches[i + 1].timestamp)
    end
  end
  
  local errors = vim.tbl_filter(function(err)
    return err.language == lang and err.timestamp > cutoff
  end, M.history.error_patterns or {})
  
  return {
    switches = total_switches,
    time_seconds = time_spent,
    errors_count = #errors,
    error_rate = total_switches > 0 and (#errors / total_switches) or 0,
  }
end

return M