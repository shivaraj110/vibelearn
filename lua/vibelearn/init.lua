local M = {}
local config = require("vibelearn.config.defaults")
local profiles = require("vibelearn.data.profiles")
local progress = require("vibelearn.data.progress")
local tracker = require("vibelearn.core.tracker")
local scheduler = require("vibelearn.core.scheduler")

M.setup = function(opts)
  local cfg = config.setup(opts)
  
  profiles.init(cfg.storage.data_path)
  progress.init(cfg.storage.data_path)
  tracker.init(cfg)
  scheduler.init(cfg)
  
  vim.api.nvim_create_user_command("VibeLearn", function()
    require("vibelearn.ui.dashboard").open()
  end, { desc = "Open VibeLearn Dashboard" })
  
  vim.api.nvim_create_user_command("VibeLearnTask", function()
    require("vibelearn.core.scheduler").suggest_task()
  end, { desc = "Start a VibeLearn task" })
  
  vim.api.nvim_create_user_command("VibeLearnStats", function()
    require("vibelearn.ui.dashboard").show_stats()
  end, { desc = "Show VibeLearn statistics" })
  
  vim.api.nvim_create_user_command("VibeLearnReset", function()
    require("vibelearn.data.profiles").reset()
    vim.notify("VibeLearn data reset!", vim.log.levels.INFO)
  end, { desc = "Reset VibeLearn progress" })
end

return M