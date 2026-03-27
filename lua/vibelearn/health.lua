local M = {}

M.check = function()
  vim.health.start("VibeLearn")
  
  M.check_neovim_version()
  M.check_opencode()
  M.check_dependencies()
  M.check_data_directory()
  M.check_configuration()
end

M.check_neovim_version = function()
  local version = vim.version()
  local major, minor = version.major, version.minor
  
  if major == 0 and minor < 9 then
    vim.health.error("VibeLearn requires Neovim >= 0.9.0")
    vim.health.info("Current version: " .. tostring(vim.version()))
  else
    vim.health.ok("Neovim version: " .. tostring(vim.version()))
  end
end

M.check_opencode = function()
  local ok = vim.fn.system("which opencode 2>/dev/null")
  
  if ok == "" then
    vim.health.warn("OpenCode CLI not found")
    vim.health.info("VibeLearn requires OpenCode CLI for AI-powered features")
    vim.health.info("Install from: https://github.com/opencode/opencode")
  else
    vim.health.ok("OpenCode CLI installed")
    
    local version = vim.fn.system("opencode --version 2>/dev/null")
    if version ~= "" then
      vim.health.info("OpenCode version: " .. version:gsub("\n", ""))
    end
  end
end

M.check_dependencies = function()
  local dependencies = {
    { name = "nui.nvim", module = "nui" },
    { name = "plenary.nvim", module = "plenary" },
  }
  
  for _, dep in ipairs(dependencies) do
    local ok, _ = pcall(require, dep.module)
    if not ok then
      vim.health.error("Missing dependency: " .. dep.name)
      vim.health.info("Install with your plugin manager")
    else
      vim.health.ok(dep.name .. " installed")
    end
  end
end

M.check_data_directory = function()
  local data_path = vim.fn.stdpath("data") .. "/vibelearn"
  
  if vim.fn.isdirectory(data_path) == 0 then
    vim.health.warn("Data directory does not exist")
    vim.health.info("Creating: " .. data_path)
    
    local ok = vim.fn.mkdir(data_path, "p")
    if ok == 1 then
      vim.health.ok("Data directory created")
    else
      vim.health.error("Failed to create data directory")
    end
  else
    vim.health.ok("Data directory exists")
    
    local permissions = vim.fn.getfperm(data_path)
    vim.health.info("Permissions: " .. permissions)
  end
end

M.check_configuration = function()
  local defaults_mod = require("vibelearn.config.defaults")
  
  vim.health.ok("VibeLearn configuration loaded")
  
  local user_config = defaults_mod.options or defaults_mod.defaults or {}
  
  if user_config.target_languages and #user_config.target_languages > 0 then
    vim.health.ok("Target languages configured: " .. table.concat(user_config.target_languages, ", "))
  else
    vim.health.ok("No target languages configured (will auto-detect)")
    vim.health.info("Set target_languages in your VibeLearn setup for personalized experience")
  end
  
  if user_config.source_language then
    vim.health.ok("Source language: " .. user_config.source_language)
  end
  
  if user_config.opencode and user_config.opencode.model then
    vim.health.ok("OpenCode model: " .. user_config.opencode.model)
  else
    vim.health.ok("Using default OpenCode model")
  end
  
  if user_config.gamification and user_config.gamification.enabled then
    vim.health.ok("Gamification enabled")
  else
    vim.health.info("Gamification: " .. (user_config.gamification and "disabled" or "default"))
  end
end

M.run = function()
  M.check()
end

return M