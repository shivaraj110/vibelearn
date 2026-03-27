local M = {}

M.defaults = {
  source_language = "python",
  target_languages = { "rust", "go", "typescript" },
  
  schedule = {
    on_filetype_switch = true,
    idle_time_minutes = 5,
    daily_goal_tasks = 3,
    reminder_interval_hours = 2,
    max_suggestions_per_day = 10,
    quiet_hours = {
      start = 22,
      stop = 8,
    },
  },
  
  gamification = {
    enabled = true,
    show_notifications = true,
    celebrate_achievements = true,
    streak_reminders = true,
    xp_multiplier = 1,
  },
  
  opencode = {
    model = "opencode-go/minimax-m2.7",
    context_lines = 100,
    max_retries = 3,
    timeout_seconds = 30,
  },
  
  dashboard = {
    position = "right",
    width = 60,
    height = 80,
    border = "rounded",
    keymaps = {
      close = "q",
      start_task = "<CR>",
      skip = "s",
      refresh = "r",
      settings = "<leader>vs",
    },
  },
  
  tracking = {
    filetypes = {
      enabled = true,
      min_time_seconds = 30,
    },
    lsp = {
      enabled = true,
      track_errors = true,
      track_warnings = true,
    },
    git = {
      enabled = true,
      commit_analysis = true,
      blame_analysis = false,
    },
  },
  
  tasks = {
    difficulty_range = { 1, 5 },
    concepts_per_task = 3,
    hints_enabled = true,
    max_hints = 3,
    time_limits = {
      easy = 15,
      medium = 30,
      hard = 60,
    },
  },
  
  storage = {
    data_path = vim.fn.stdpath("data") .. "/vibelearn",
    backup_enabled = true,
    backup_interval_days = 7,
    max_history_days = 30,
  },
  
  ui = {
    notifications = {
      enabled = true,
      minimum_level = "info",
      timeout = 3000,
    },
    progress_display = {
      show_xp_bar = true,
      show_streak = true,
      show_achievements = true,
      show_language_breakdown = true,
    },
  },
}

M.options = {}

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

M.get = function(key)
  if key then
    return M.options[key]
  end
  return M.options
end

return M