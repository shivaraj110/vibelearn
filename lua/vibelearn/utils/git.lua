local M = {}
local log = require("vibelearn.utils.logger")

M.is_git_repo = function()
  local ok = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null")
  return ok:gsub("%s+", "") == "true"
end

M.get_current_branch = function()
  if not M.is_git_repo() then
    return nil
  end
  
  local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null")
  return branch:gsub("%s+", "")
end

M.get_remote_url = function()
  if not M.is_git_repo() then
    return nil
  end
  
  local url = vim.fn.system("git config --get remote.origin.url 2>/dev/null")
  return url:gsub("%s+", "")
end

M.get_filetype_stats = function(days)
  if not M.is_git_repo() then
    return {}
  end
  
  local since = ""
  if days then
    since = string.format("--since='%d days ago'", days)
  end
  
  local cmd = string.format(
    "git log %s --name-only --pretty=format: | grep -v '^$' | sort | uniq -c | sort -rn",
    since
  )
  
  local ok, result = pcall(vim.fn.system, cmd)
  if not ok then
    return {}
  end
  
  local stats = {}
  for line in vim.gmatch(result, "[^\n]+") do
    local count, file = line:match("(%d+)%s+(.+)")
    if count and file then
      local ext = file:match("%.(.+)$")
      if ext then
        stats[ext] = (stats[ext] or 0) + tonumber(count)
      end
    end
  end
  
  return stats
end

return M