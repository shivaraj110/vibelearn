local M = {}
local log = require("vibelearn.utils.logger")
local history = require("vibelearn.data.history")
local progress = require("vibelearn.data.progress")

M.config = nil
M.enabled = false
M.current_state = {
  filetype = nil,
  buffer = nil,
  file = nil,
  start_time = nil,
  last_activity = nil,
  error_count =0,
  warning_count = 0,
}

M.autocmd_group = nil
M.lsp_attached = {}

M.init = function(cfg)
  M.config = cfg
  M.enabled = true
  
  M.autocmd_group = vim.api.nvim_create_augroup("VibeLearnTracker", { clear = true })
  
  if M.config.tracking.filetypes.enabled then
    M.setup_filetype_tracking()
  end
  
  if M.config.tracking.lsp.enabled then
    M.setup_lsp_tracking()
  end
  
  if M.config.tracking.git.enabled then
    M.setup_git_tracking()
  end
  
  M.track_idle_time()
  
  log.info("Activity tracker initialized")
end

M.setup_filetype_tracking = function()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = M.autocmd_group,
    callback = M.on_buf_enter,
    desc = "VibeLearn: Track buffer enter events",
  })
  
  vim.api.nvim_create_autocmd("BufWrite", {
    group = M.autocmd_group,
    callback = M.on_buf_write,
    desc = "VibeLearn: Track buffer write events",
  })
  
  vim.api.nvim_create_autocmd("FileType", {
    group = M.autocmd_group,
    callback = M.on_filetype_change,
    desc = "VibeLearn: Track filetype changes",
  })
  
  log.debug("Filetype tracking enabled")
end

M.setup_lsp_tracking = function()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = M.autocmd_group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        M.on_lsp_attach(client, args.buf)
      end
    end,
    desc = "VibeLearn: Track LSP attachments",
  })
  
  vim.api.nvim_create_autocmd("LspDetach", {
    group = M.autocmd_group,
    callback = function(args)
      M.on_lsp_detach(args.buf)
    end,
    desc = "VibeLearn: Track LSP detachments",
  })
  
  log.debug("LSP tracking enabled")
end

M.setup_git_tracking = function()
  vim.api.nvim_create_autocmd("User", {
    group = M.autocmd_group,
    pattern = "GitCommitPost",
    callback = M.on_git_commit,
    desc = "VibeLearn: Track git commits",
  })
  
  log.debug("Git tracking enabled")
end

M.on_buf_enter = function(args)
  if not M.enabled then
    return
  end
  
  local buf = args.buf
  local ft = vim.bo[buf].filetype
  
  if ft == "" or ft == nil then
    return
  end
  
  if M.current_state.filetype and M.current_state.filetype ~= ft then
    M.record_filetype_session()
    local previous_ft = M.current_state.filetype
    M.current_state = {
      filetype = ft,
      buffer = buf,
      file = vim.api.nvim_buf_get_name(buf),
      start_time = os.time(),
      last_activity = os.time(),
      error_count = 0,
      warning_count = 0,
    }
    
    history.record_filetype_switch(previous_ft, ft)
  else
    if not M.current_state.filetype then
      M.current_state = {
        filetype = ft,
        buffer = buf,
        file = vim.api.nvim_buf_get_name(buf),
        start_time = os.time(),
        last_activity = os.time(),
        error_count = 0,
        warning_count = 0,
      }
    else
      M.current_state.last_activity = os.time()
    end
  end
  
  log.debug("Buffer entered:", ft, "file:", M.current_state.file)
end

M.on_buf_write = function(args)
  if not M.enabled then
    return
  end
  
  M.current_state.last_activity = os.time()
  
  local buf = args.buf
  local ft = vim.bo[buf].filetype
  
  if ft and M.current_state.filetype == ft then
    history.record_activity("file_saved", {
      filetype = ft,
      file = vim.api.nvim_buf_get_name(buf),
      lines = vim.api.nvim_buf_line_count(buf),
    })
  end
  
  log.debug("Buffer written:", ft)
end

M.on_filetype_change = function(args)
  if not M.enabled then
    return
  end
  
  local ft = args.match
  if not ft or ft == "" then
    return
  end
  
  M.current_state.last_activity = os.time()
  
  log.debug("Filetype changed to:", ft)
end

M.on_lsp_attach = function(client, bufnr)
  if not M.enabled then
    return
  end
  
  M.lsp_attached[bufnr] = M.lsp_attached[bufnr] or{}
  M.lsp_attached[bufnr][client.id] = client.name
  
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    buffer = bufnr,
    callback = function()
      M.on_diagnostics_changed(bufnr)
    end,
    desc = "VibeLearn: Track LSP diagnostics",
  })
  
  log.debug("LSP attached:", client.name, "to buffer:", bufnr)
end

M.on_lsp_detach = function(bufnr)
  M.lsp_attached[bufnr] = nil
  log.debug("LSP detached from buffer:", bufnr)
end

M.on_diagnostics_changed = function(bufnr)
  if not M.enabled or not M.config.tracking.lsp.track_errors then
    return
  end
  
  local diagnostics = vim.diagnostic.get(bufnr)
  local current_ft = M.current_state.filetype
  
  if not current_ft then
    return
  end
  
  local error_count = 0
  local warning_count = 0
  
  for _, diagnostic in ipairs(diagnostics) do
    if diagnostic.severity == vim.diagnostic.severity.ERROR then
      error_count = error_count +1
      
      if M.config.tracking.lsp.track_errors then
        history.record_lsp_error(
          current_ft,
          diagnostic.code or "unknown",
          diagnostic.message,
          vim.api.nvim_buf_get_name(bufnr),
          diagnostic.lnum +1
        )
      end
    elseif diagnostic.severity == vim.diagnostic.severity.WARN then
      if M.config.tracking.lsp.track_warnings then
        warning_count = warning_count + 1
      end
    end
  end
  
  local error_delta = error_count - M.current_state.error_count
  if error_delta > 0 then
    M.current_state.error_count = error_count
    M.current_state.warning_count = warning_count
    
    history.record_activity("diagnostics_changed", {
      filetype = current_ft,
      errors = error_count,
      warnings = warning_count,
      new_errors = error_delta,
    })
  end
  
  log.debug("Diagnostics updated:", error_count, "errors,", warning_count, "warnings")
end

M.on_git_commit = function()
  if not M.enabled or not M.config.tracking.git.commit_analysis then
    return
  end
  
  local ok, result = pcall(function()
    return vim.fn.system("git log -1 --pretty=format:'%H|%s' --numstat")
  end)
  
  if not ok then
    log.warn("Failed to get git commit info")
    return
  end
  
  local lines = vim.split(result, "\n")
  if #lines < 1 then
    return
  end
  
  local commit_info = vim.split(lines[1],"|")
  if #commit_info < 2 then
    return
  end
  
  local commit_hash = commit_info[1]
  local commit_message = commit_info[2]
  local files_changed = {}
  local insertions = 0
  local deletions = 0
  
  for i = 2, #lines do
    local parts = vim.split(lines[i], "\t")
    if #parts >= 3 then
      local additions = tonumber(parts[1]) or 0
      local deletess = tonumber(parts[2]) or 0
      local file = parts[3]
      
      insertions = insertions + additions
      deletions = deletions + deletess
      
      table.insert(files_changed, file)
    end
  end
  
  history.record_git_commit(commit_hash, commit_message, files_changed, insertions, deletions)
  
  log.debug("Git commit recorded:", commit_hash)
end

M.record_filetype_session = function()
  if not M.current_state.filetype or not M.current_state.start_time then
    return
  end
  
  local duration = os.time() - M.current_state.start_time
  local min_time = M.config.tracking.filetypes.min_time_seconds or 30
  
  if duration < min_time then
    log.debug("Session too short, not recording")
    return
  end
  
  history.record_session("filetype_session", duration, {
    filetype = M.current_state.filetype,
    file = M.current_state.file,
    errors = M.current_state.error_count,
    warnings = M.current_state.warning_count,
  })
  
  progress.add_language_xp(
    M.current_state.filetype,
    math.floor(duration / 60),
    "coding_time"
  )
  
  log.debug("Session recorded:", M.current_state.filetype, "for", duration, "seconds")
end

M.track_idle_time = function()
  local check_interval = 60
  
  vim.fn.timer_start(check_interval * 1000, function()
    if not M.enabled then
      return
    end
    
    local idle_time = vim.fn.reltimefloat(vim.fn.reltime(M.current_state.last_activity or os.time()))
    
    if idle_time > M.config.schedule.idle_time_minutes *60 then
      M.on_idle()
    end
  end, {["repeat"] = -1})
end

M.on_idle = function()
  log.debug("User idle for", M.config.schedule.idle_time_minutes, "minutes")
  
  history.record_activity("idle_detected", {
    filetype = M.current_state.filetype,
    idle_duration = M.config.schedule.idle_time_minutes,
  })
end

M.get_current_state = function()
  return M.current_state
end

M.get_filetype_time = function(lang, hours)
  local cutoff = os.time() - (hours * 60 * 60)
  local activities = history.get_activities_by_type("filetype_session", nil)
  
  local total_seconds = 0
  for _, act in ipairs(activities) do
    if act.data.filetype == lang and act.timestamp > cutoff then
      total_seconds = total_seconds + act.data.duration_seconds
    end
  end
  
  return total_seconds
end

M.get_recent_errors = function(lang, limit)
  return history.get_error_patterns(lang, limit)
end

M.get_filetype_stats = function(days)
  local usage = {}
  
  local activities = history.get_activities_by_type("filetype_switch", nil)
  local cutoff = os.time() - (days * 24 * 60 * 60)
  
  for _, act in ipairs(activities) do
    if act.timestamp > cutoff then
      local ft = act.data.to
      if ft then
        usage[ft] = (usage[ft] or 0) + 1
      end
    end
  end
  
  return usage
end

M.enable = function()
  M.enabled = true
  log.info("Activity tracker enabled")
end

M.disable = function()
  M.enabled = false
  log.info("Activity tracker disabled")
end

M.toggle = function()
  M.enabled = not M.enabled
  log.info("Activity tracker", M.enabled and"enabled" or "disabled")
end

return M