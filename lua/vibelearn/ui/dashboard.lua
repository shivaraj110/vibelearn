local M = {}
local NuiLayout = require("nui.layout")
local NuiPopup = require("nui.popup")
local NuiText = require("nui.text")
local NuiLine = require("nui.line")
local log = require("vibelearn.utils.logger")
local progress = require("vibelearn.data.progress")
local profiles = require("vibelearn.data.profiles")
local scheduler = require("vibelearn.core.scheduler")
local tasks = require("vibelearn.data.tasks")

M.layout = nil
M.popups = {}
M.current_task = nil

M.open = function()
  if M.layout then
    M.layout:show()
    return
  end
  
  M.create_dashboard()
end

M.create_dashboard = function()
  local profile = profiles.get()
  local progress_data = progress.get()
  local stats = progress.get_stats_summary()
  
  local layout = NuiLayout({
    position = "50%",
    size = {
      width = "80%",
      height = "90%",
    },
  }, NuiLayout.Box({
    NuiLayout.Box({
      size = "20%",
      NuiLayout.Box({
        size = "50%",
        M.create_header_popup(profile),
      }, { grow = true }),
      NuiLayout.Box({
        size = "50%",
        M.create_stats_popup(stats),
      }, { grow = true }),
    }, { dir = "row", grow = true }),
    NuiLayout.Box({
      size = "60%",
      M.create_main_popup(progress_data),
    }, { grow = true }),
    NuiLayout.Box({
      size = "20%",
      M.create_actions_popup(),
    }),
  }, { dir = "col", grow = true }))
  
  layout:mount()
  M.layout = layout
  
  M.setup_keymaps()
end

M.create_header_popup = function(profile)
  local popup = NuiPopup({
    border = {
      style = "rounded",
      text = {
        top = NuiText("VibeLearn Dashboard", "Title"),
      },
    },
    buf_options = {
      modifiable = false,
      readonly = true,
    },
  })
  
  local lines = {}
  table.insert(lines, NuiLine():append("Welcome, " .. (profile.user.name or "Developer"), "String"))
  table.insert(lines, NuiLine():append(""))
  
  local targets = table.concat(profile.user.target_languages or {}, ", ")
  table.insert(lines, NuiLine():append("Learning: ", "Keyword"):append(targets, "Identifier"))
  
  local streak = progress_data.streak or { current = 0, longest = 0 }
  table.insert(lines, NuiLine():append("Streak: ", "Keyword"):append(tostring(streak.current), "Number"):append(" days", "String"))
  
  M.render_lines(popup, lines)
  
  return popup
end

M.create_stats_popup = function(stats)
  local popup = NuiPopup({
    border = {
      style = "rounded",
      text = {
        top = NuiText("Progress", "Title"),
      },
    },
    buf_options = {
      modifiable = false,
      readonly = true,
    },
  })
  
  local lines = {}
  table.insert(lines, NuiLine():append("Level: ", "Keyword"):append(tostring(stats.level), "Number"))
  table.insert(lines, NuiLine():append("XP: ", "Keyword"):append(tostring(stats.total_xp), "Number"))
  table.insert(lines, NuiLine():append("Tasks: ", "Keyword"):append(tostring(stats.tasks_completed), "Number"))
  table.insert(lines, NuiLine():append("Languages: ", "Keyword"):append(tostring(stats.languages_learned), "Number"))
  table.insert(lines, NuiLine():append("Time: ", "Keyword"):append(string.format("%.1f", stats.total_time_hours), "Number"):append("h", "String"))
  
  M.render_lines(popup, lines)
  
  return popup
end

M.create_main_popup = function(progress_data)
  local popup = NuiPopup({
    border = {
      style = "rounded",
      text = {
        top = NuiText("Languages", "Title"),
      },
    },
    buf_options = {
      modifiable = false,
      readonly = true,
    },
  })
  
  local lines = {}
  
  for lang, lang_data in pairs(progress_data.languages or {}) do
    local line = NuiLine()
    line:append(lang, "Identifier")
    line:append(" - ", "String")
    line:append(lang_data.proficiency or "beginner", "Keyword")
    line:append(" (", "String")
    line:append(tostring(lang_data.xp or 0), "Number")
    line:append(" XP)", "String")
    
    local progress_pct = progress.get_progress_percentage(lang)
    line:append(" ", "String")
    line:append(M.draw_progress_bar(progress_pct), "String")
    
    table.insert(lines, line)
  end
  
  if #lines == 0 then
    table.insert(lines, NuiLine():append("No languages tracked yet", "Comment"))
    table.insert(lines, NuiLine():append("Start by working on a target language", "Comment"))
  end
  
  M.render_lines(popup, lines)
  
  return popup
end

M.create_actions_popup = function()
  local popup = NuiPopup({
    border = {
      style = "rounded",
      text = {
        top = NuiText("Actions", "Title"),
      },
    },
    buf_options = {
      modifiable = false,
      readonly = true,
    },
  })
  
  local lines = {}
  table.insert(lines, NuiLine():append("[t] ", "Keyword"):append("Get new task", "String"))
  table.insert(lines, NuiLine():append("[s] ", "Keyword"):append("View statistics", "String"))
  table.insert(lines, NuiLine():append("[r] ", "Keyword"):append("Refresh dashboard", "String"))
  table.insert(lines, NuiLine():append("[c] ", "Keyword"):append("Configure settings", "String"))
  table.insert(lines, NuiLine():append("[q] ", "Keyword"):append("Close dashboard", "String"))
  
  if M.current_task then
    table.insert(lines, NuiLine():append(""))
    table.insert(lines, NuiLine():append("Current Task: ", "Title"))
    table.insert(lines, NuiLine():append(M.current_task.title, "Identifier"))
  end
  
  M.render_lines(popup, lines)
  
  return popup
end

M.draw_progress_bar = function(percentage)
  local bar_length = 20
  local filled = math.floor(percentage / 100 * bar_length)
  local empty = bar_length - filled
  
  local bar = "["
  for i = 1, filled do
    bar = bar .. "█"
  end
  for i = 1, empty do
    bar = bar .. "░"
  end
  bar = bar .. "]"
  
  return string.format("%s %d%%", bar, percentage)
end

M.render_lines = function(popup, lines)
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, {})
  
  for i, line in ipairs(lines) do
    if type(line) == "table" and line.append then
      line:render(popup.bufnr, -1, i)
    else
      vim.api.nvim_buf_set_lines(popup.bufnr, i - 1, i, false, { tostring(line) })
    end
  end
end

M.setup_keymaps = function()
  local maps = M.config and M.config.dashboard and M.config.dashboard.keymaps or {
    close = "q",
    task = "t",
    stats = "s",
    refresh = "r",
    config = "c",
  }
  
  for _, popup in pairs(M.popups) do
    popup:map("n", maps.close, function()
      M.close()
    end, { noremap = true })
    
    popup:map("n", maps.task, function()
      M.new_task()
    end, { noremap = true })
    
    popup:map("n", maps.stats, function()
      M.show_stats()
    end, { noremap = true })
    
    popup:map("n", maps.refresh, function()
      M.refresh()
    end, { noremap = true })
  end
end

M.close = function()
  if M.layout then
    M.layout:unmount()
    M.layout = nil
    M.popups = {}
  end
end

M.refresh = function()
  M.close()
  M.open()
end

M.new_task = function()
  scheduler.suggest_task()
end

M.show_stats = function()
  local stats = progress.get_stats_summary()
  local lines = {}
  
  table.insert(lines, "=== VibeLearn Statistics ===")
  table.insert(lines, "")
  table.insert(lines, string.format("Level: %d", stats.level))
  table.insert(lines, string.format("Total XP: %d", stats.total_xp))
  table.insert(lines, string.format("Current Streak: %d days", stats.streak_days))
  table.insert(lines, string.format("Longest Streak: %d days", stats.longest_streak))
  table.insert(lines, string.format("Tasks Completed: %d", stats.tasks_completed))
  table.insert(lines, string.format("Languages Tracked: %d", stats.languages_learned))
  table.insert(lines, string.format("Achievements: %d/%d", stats.achievements_unlocked, #progress.get().achievements or 0))
  table.insert(lines, string.format("Total Time: %.1f hours", stats.total_time_hours))
  
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

M.open_task = function(task)
  M.current_task = task
  
  local lines = {}
  table.insert(lines, "=== " .. task.title .. " ===")
  table.insert(lines, "")
  table.insert(lines, "Language: " .. (task.language or "Unknown"))
  table.insert(lines, "Difficulty: " .. string.rep("★", task.difficulty or 3))
  table.insert(lines, "Estimated Time: " .. (task.estimated_time or "15 minutes"))
  table.insert(lines, "")
  table.insert(lines, "Description:")
  table.insert(lines, task.description or "No description available")
  table.insert(lines, "")
  
  if task.concepts and #task.concepts > 0 then
    table.insert(lines, "Concepts:")
    for _, concept in ipairs(task.concepts) do
      table.insert(lines, "  - " .. concept)
    end
    table.insert(lines, "")
  end
  
  if task.starter_code and task.starter_code ~= "" then
    table.insert(lines, "Starter Code:")
    table.insert(lines, task.starter_code)
    table.insert(lines, "")
  end
  
  table.insert(lines, "[ENTER] Start Task")
  table.insert(lines, "[h] View Hints")
  table.insert(lines, "[s] Skip Task")
  table.insert(lines, "[q] Close")
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "vibelearn-task")
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 80,
    height = 30,
    row = 5,
    col = 5,
    style = "minimal",
    border = "rounded",
  })
  
  vim.keymap.set("n", "<CR>", function()
    scheduler.start_task(task.id)
    vim.api.nvim_win_close(win, false)
    M.close()
  end, { buffer = buf, noremap = true })
  
  vim.keymap.set("n", "h", function()
    scheduler.get_hint(task.id)
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