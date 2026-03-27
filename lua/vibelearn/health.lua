local M = {}

M.check = function()
  vim.health.start("VibeLearn")
  
  -- Check Neovim version
  local version = vim.version()
  local major, minor = version.major, version.minor
  
  if major == 0 and minor < 9 then
    vim.health.error("VibeLearn requires Neovim >= 0.9.0")
    vim.health.info("Current version: " .. tostring(vim.version()))
  else
    vim.health.ok("Neovim version: " .. tostring(vim.version()))
  end
  
  -- Check OpenCode CLI
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
  
  -- Check dependencies
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
  
  -- Check data directory
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
  
  -- Check configuration
  local ok, defaults_mod = pcall(require, "vibelearn.config.defaults")
  if not ok then
    vim.health.error("VibeLearn configuration not loaded")
    return
  end
  
  vim.health.ok("VibeLearn configuration loaded")
  
  local user_config = defaults_mod.options or defaults_mod.defaults or {}
  
  -- Check target languages
  if user_config.target_languages and #user_config.target_languages > 0 then
    vim.health.ok("Target languages: " .. table.concat(user_config.target_languages, ", "))
  else
    vim.health.info("No target languages configured (will auto-detect based on filetypes)")
    vim.health.info("Set target_languages in your config for better experience")
  end
  
  -- Check source language
  if user_config.source_language then
    vim.health.ok("Source language: " .. user_config.source_language)
  else
    vim.health.info("Source language: not configured (will use primary language)")
  end
  
  -- Check OpenCode model
  if user_config.opencode and user_config.opencode.model then
    vim.health.ok("OpenCode model: " .. user_config.opencode.model)
  else
    vim.health.info("OpenCode: using default model")
  end
  
  -- Check gamification
  if user_config.gamification and user_config.gamification.enabled then
    vim.health.ok("Gamification: enabled")
  else
    vim.health.info("Gamification: disabled or using defaults")
  end
end

return M