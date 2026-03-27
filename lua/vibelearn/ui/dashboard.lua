local M = {}
local NuiPopup = require("nui.popup")
local log = require("vibelearn.utils.logger")
local progress = require("vibelearn.data.progress")
local profiles = require("vibelearn.data.profiles")
local scheduler = require("vibelearn.core.scheduler")

M.layout = nil
M.popups = {}
M.current_task = nil
M.config = nil

M.open = function()
  if M.layout and vim.api.nvim_win_is_valid(M.layout) then
    vim.api.nvim_set_current_win(M.layout)
    return
  end
  
  M.create_dashboard()
end

M.create_dashboard = function()
  local profile = profiles.get()
  local progress_data = progress.get()
  local stats = progress.get_stats_summary()
  
  local lines = {}
  table.insert(lines, "╔════════════════════════════════════════════════════════════╗")
  table.insert(lines, "║                    VibeLearn Dashboard                      ║")
  table.insert(lines, "╠════════════════════════════════════════════════════════════╣")
  table.insert(lines, "")
  table.insert(lines, string.format("  Welcome, %s", profile.user.name or "Developer"))
  table.insert(lines, "")
  
  if profile.user.target_languages and #profile.user.target_languages > 0 then
    table.insert(lines, string.format("  Learning: %s", table.concat(profile.user.target_languages, ", ")))
  else
    table.insert(lines, "  Learning: (not configured)")
  end
  
  local streak = progress_data.streak or { current = 0, longest = 0 }
  table.insert(lines, string.format("  Streak: %d days (longest: %d)", streak.current, streak.longest))
  table.insert(lines, "")
  
  table.insert(lines, "╠════════════════════════════════════════════════════════════╣")
  table.insert(lines, "║                      Progress                               ║")
  table.insert(lines, "╠════════════════════════════════════════════════════════════╣")
  table.insert(lines, "")
  table.insert(lines, string.format("  Level: %d", stats.level))
  table.insert(lines, string.format("  XP: %d", stats.total_xp))
  table.insert(lines, string.format("  Tasks Completed: %d", stats.tasks_completed))
  table.insert(lines, string.format("  Languages: %d", stats.languages_learned))
  table.insert(lines, string.format("  Time: %.1f hours", stats.total_time_hours))
  table.insert(lines, "")
  
  table.insert(lines, "╠════════════════════════════════════════════════════════════╣")
  table.insert(lines, "║                      Actions                                 ║")
  table.insert(lines, "╠════════════════════════════════════════════════════════════╣")
  table.insert(lines, "")
  table.insert(lines, "  [t] Get new task")
  table.insert(lines, "  [s] View statistics")
  table.insert(lines, "  [r] Refresh dashboard")
  table.insert(lines, "  [q] Close")
  table.insert(lines, "")
  table.insert(lines, "╚════════════════════════════════════════════════════════════╝")
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "vibelearn-dashboard")
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 60,
    height = 30,
    row = 5,
    col = 10,
    style = "minimal",
    border = "rounded",
    title = " VibeLearn ",
    title_pos = "center",
  })
  
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, false)
    M.layout = nil
  end, { buffer = buf, noremap = true })
  
  vim.keymap.set("n", "t", function()
    vim.api.nvim_win_close(win, false)
    M.new_task()
  end, { buffer = buf, noremap = true })
  
  vim.keymap.set("n", "s", function()
    vim.api.nvim_win_close(win, false)
    M.show_stats()
  end, { buffer = buf, noremap = true })
  
  vim.keymap.set("n", "r", function()
    vim.api.nvim_win_close(win, false)
    M.open()
  end, { buffer = buf, noremap = true })
  
  M.layout = win
end

M.new_task = function()
  scheduler.suggest_task()
end

M.show_stats = function()
  local stats = progress.get_stats_summary()
  local lines = {}
  
  table.insert(lines, "╔════════════════════════════════════════════════════════════╗")
  table.insert(lines, "║                  VibeLearn Statistics                        ║")
  table.insert(lines, "╠════════════════════════════════════════════════════════════╣")
  table.insert(lines, "")
  table.insert(lines, string.format("  Level: %d", stats.level))
  table.insert(lines, string.format("  Total XP: %d", stats.total_xp))
  table.insert(lines, string.format("  Current Streak: %d days", stats.streak_days))
  table.insert(lines, string.format("  Longest Streak: %d days", stats.longest_streak))
  table.insert(lines, string.format("  Tasks Completed: %d", stats.tasks_completed))
  table.insert(lines, string.format("  Languages Tracked: %d", stats.languages_learned))
  table.insert(lines, string.format("  Achievements: %d", stats.achievements_unlocked))
  table.insert(lines, string.format("  Total Time: %.1f hours", stats.total_time_hours))
  table.insert(lines, "")
  table.insert(lines, "╚════════════════════════════════════════════════════════════╝")
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "vibelearn-stats")
  
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 60,
    height = 15,
    row = 10,
    col = 10,
    style = "minimal",
    border = "rounded",
  })
end

M.close = function()
  if M.layout then
    pcall(vim.api.nvim_win_close, M.layout, false)
    M.layout = nil
  end
end

M.open_task = function(task)
  M.current_task = task
  
  if not task then
    vim.notify("No task available", vim.log.levels.WARN)
    return
  end
  
  local lines = {}
  table.insert(lines, "╔════════════════════════════════════════════════════════════╗")
  table.insert(lines, string.format("║ %-60s ║", task.title or "Learning Task"))
  table.insert(lines, "╠════════════════════════════════════════════════════════════╣")
  table.insert(lines, "")
  table.insert(lines, string.format("  Language: %s", task.language or "Unknown"))
  table.insert(lines, string.format("  Difficulty: %s", string.rep("★", task.difficulty or 3)))
  table.insert(lines, string.format("  Time: %s", task.estimated_time or "15 minutes"))
  table.insert(lines, "")
  table.insert(lines, "  Description:")
  table.insert(lines, string.format("    %s", task.description or "No description"))
  table.insert(lines, "")
  
  if task.concepts and #task.concepts > 0 then
    table.insert(lines, "  Concepts:")
    for _, concept in ipairs(task.concepts) do
      table.insert(lines, string.format("    - %s", concept))
    end
    table.insert(lines, "")
  end
  
  table.insert(lines, "╠════════════════════════════════════════════════════════════╣")
  table.insert(lines, "  [Enter] Start Task")
  table.insert(lines, "  [h] View Hints")
  table.insert(lines, "  [s] Skip Task")
  table.insert(lines, "  [q] Close")
  table.insert(lines, "╚════════════════════════════════════════════════════════════╝")
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "vibelearn-task")
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 66,
    height = 30,
    row = 5,
    col = 7,
    style = "minimal",
    border = "rounded",
  })
  
  vim.keymap.set("n", "<CR>", function()
    if scheduler.start_task(task.id) then
      vim.api.nvim_win_close(win, false)
      M.close()
    end
  end, { buffer = buf, noremap = true })
  
  vim.keymap.set("n", "h", function()
    local hint = scheduler.get_hint(task.id)
    if hint then
      vim.notify("💡 Hint: " .. hint, vim.log.levels.INFO)
    end
  end, { buffer = buf, noremap = true })
  
  vim.keymap.set("n", "s", function()
    scheduler.skip_task(task.id, "User skipped")
    vim.api.nvim_win_close(win, false)
  end, { buffer = buf, noremap = true })
  
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, false)
  end, { buffer = buf, noremap = true })
end

return M