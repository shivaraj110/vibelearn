local M = {}
local log = require("vibelearn.utils.logger")

M.get_active_clients = function(bufnr)
  bufnr = bufnr or 0
  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  return clients or {}
end

M.get_diagnostics = function(bufnr, severity)
  bufnr = bufnr or 0
  severity = severity or nil
  
  local diagnostics = vim.diagnostic.get(bufnr, { severity = severity })
  return diagnostics
end

M.get_error_count = function(bufnr)
  local errors = M.get_diagnostics(bufnr, vim.diagnostic.severity.ERROR)
  return #errors
end

M.get_warning_count = function(bufnr)
  local warnings = M.get_diagnostics(bufnr, vim.diagnostic.severity.WARN)
  return #warnings
end

M.get_diagnostics_summary = function(bufnr)
  return {
    errors = #M.get_diagnostics(bufnr, vim.diagnostic.severity.ERROR),
    warnings = #M.get_diagnostics(bufnr, vim.diagnostic.severity.WARN),
    info = #M.get_diagnostics(bufnr, vim.diagnostic.severity.INFO),
    hints = #M.get_diagnostics(bufnr, vim.diagnostic.severity.HINT),
  }
end

return M