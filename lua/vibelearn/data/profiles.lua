local M = {}
local Path = require("plenary.path")
local log = require("vibelearn.utils.logger")

M.profile_file = nil
M.profile = nil

local DEFAULT_PROFILE = {
  version = 1,
  created_at = nil,
  updated_at = nil,
  user = {
    id = nil,
    name = nil,
    primary_language = "python",
    target_languages = {},
    preferences = {
      daily_goal = 3,
      difficulty_preference = "adaptive",
      notification_frequency = "normal",
    },
  },
  learning_paths = {},
  achievements_unlocked = {},
  total_xp = 0,
  current_level = 1,
  streak = {
    current = 0,
    longest = 0,
    last_activity = nil,
  },
}

M.init = function(data_path)
  M.profile_file = Path:new(data_path, "profile.json")
  M.profile = M.load()
  log.debug("Profile initialized", M.profile)
end

M.load = function()
  if not M.profile_file or not M.profile_file:exists() then
    return M.create_default()
  end
  
  local ok, data = pcall(function()
    local content = M.profile_file:read()
    return vim.json.decode(content)
  end)
  
  if not ok or not data then
    log.warn("Failed to load profile, creating new one")
    return M.create_default()
  end
  
  return vim.tbl_deep_extend("force", DEFAULT_PROFILE, data)
end

M.create_default = function()
  local profile = vim.deepcopy(DEFAULT_PROFILE)
  profile.created_at = os.date("%Y-%m-%dT%H:%M:%SZ")
  profile.updated_at = profile.created_at
  profile.user.id = M.generate_id()
  profile.user.name = vim.env.USER or "Anonymous"
  
  M.save(profile)
  return profile
end

M.save = function(profile)
  if not profile then
    profile = M.profile
  end
  
  if not M.profile_file then
    log.error("Profile not initialized")
    return false
  end
  
  profile.updated_at = os.date("%Y-%m-%dT%H:%M:%SZ")
  
  local ok, encoded = pcall(vim.json.encode, profile)
  if not ok then
    log.error("Failed to encode profile")
    return false
  end
  
  M.profile_file:write(encoded, "w")
  log.debug("Profile saved")
  return true
end

M.get = function()
  if not M.profile then
    M.profile = M.load()
  end
  return M.profile
end

M.update = function(updates)
  if not M.profile then
    log.error("Profile not initialized")
    return false
  end
  
  M.profile = vim.tbl_deep_extend("force", M.profile, updates)
  M.save()
  return true
end

M.set_primary_language = function(lang)
  return M.update({ user = { primary_language = lang } })
end

M.add_target_language = function(lang)
  local profile = M.get()
  if not vim.tbl_contains(profile.user.target_languages, lang) then
    table.insert(profile.user.target_languages, lang)
    M.save()
  end
end

M.remove_target_language = function(lang)
  local profile = M.get()
  local idx = vim.tbl_contains(profile.user.target_languages, lang)
  if idx then
    table.remove(profile.user.target_languages, idx)
    M.save()
  end
end

M.reset = function()
  if M.profile_file and M.profile_file:exists() then
    M.profile_file:delete()
  end
  M.profile = M.create_default()
  log.info("Profile reset")
end

M.generate_id = function()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format("%x", v)
  end)
end

M.export = function()
  local profile = M.get()
  return vim.json.encode(profile)
end

M.import = function(json_str)
  local ok, data = pcall(vim.json.decode, json_str)
  if not ok then
    log.error("Failed to import profile")
    return false
  end
  
  M.profile = vim.tbl_deep_extend("force", DEFAULT_PROFILE, data)
  M.save()
  return true
end

return M