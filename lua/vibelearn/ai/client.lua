local M = {}
local log = require("vibelearn.utils.logger")
local prompts = require("vibelearn.ai.prompts")

M.config = nil
M.last_request_time = nil
M.request_count = 0

M.init = function(cfg)
  M.config = cfg.opencode
  M.check_opencode_available()
end

M.check_opencode_available = function()
  local ok = vim.fn.system("which opencode")
  if ok == "" then
    log.warn("OpenCode CLI not found. VibeLearn requires OpenCode to be installed.")
    return false
  end
  
  log.debug("OpenCode CLI found")
  return true
end

M.query = function(prompt, context, callback)
  if not M.check_opencode_available() then
    if callback then
      callback(nil, "OpenCode CLI not available")
    end
    return nil
  end
  
  local model = M.config.model or "opencode-go/minimax-m2.7"
  local timeout = M.config.timeout_seconds or 30
  
  local prompt_with_context = M.build_prompt(prompt, context)
  
  local temp_file = vim.fn.tempname() .. ".txt"
  vim.fn.writefile({ prompt_with_context }, temp_file)
  
  local cmd = string.format(
    "opencode chat --model '%s' --prompt '%s' --timeout '%d' < '%s'",
    model,
    prompt_with_context:gsub("'", "'\\''"),
    timeout,
    temp_file
  )
  
  M.request_count = M.request_count + 1
  M.last_request_time = os.time()
  
  if callback then
    M.query_async(cmd, callback, temp_file)
  else
    local result = M.query_sync(cmd)
    vim.fn.delete(temp_file)
    return result
  end
end

M.query_sync = function(cmd)
  local ok, result = pcall(vim.fn.system, cmd)
  
  if not ok then
    log.error("OpenCode query failed:", result)
    return nil
  end
  
  return M.parse_response(result)
end

M.query_async = function(cmd, callback, temp_file)
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data, _)
      local output = table.concat(data, "\n")
      local result = M.parse_response(output)
      
      if callback then
        callback(result, nil)
      end
      
      vim.fn.delete(temp_file)
    end,
    on_stderr = function(_, data, _)
      local error_msg = table.concat(data, "\n")
      log.error("OpenCode error:", error_msg)
      
      if callback then
        callback(nil, error_msg)
      end
      
      vim.fn.delete(temp_file)
    end,
  })
end

M.build_prompt = function(prompt_template, context)
  local prompt = prompt_template
  
  if context then
    for key, value in pairs(context) do
      prompt = prompt:gsub("{{" .. key .. "}}", tostring(value))
    end
  end
  
  return prompt
end

M.parse_response = function(raw)
  if not raw or raw == "" then
    return nil
  end
  
  local ok, decoded = pcall(vim.json.decode, raw)
  
  if ok and decoded then
    return decoded
  end
  
  return {
    raw = raw,
    text = raw,
  }
end

M.generate_task = function(source_lang, target_lang, difficulty, focus_areas, callback)
  local context = {
    source_lang = source_lang,
    target_lang = target_lang,
    difficulty = difficulty,
    focus_areas = table.concat(focus_areas or {}, ", "),
    source_level = M.get_language_level(source_lang),
    target_level = M.get_language_level(target_lang),
  }
  
  local prompt = M.build_prompt(prompts.GENERATE_TASK, context)
  
  M.query(prompt, context, function(result, err)
    if err then
      log.error("Failed to generate task:", err)
      if callback then
        callback(nil, err)
      end
      return
    end
    
    local task = M.parse_task_response(result)
    
    if callback then
      callback(task, nil)
    end
  end)
end

M.parse_task_response = function(response)
  if not response then
    return nil
  end
  
  if type(response) == "string" then
    local ok, decoded = pcall(vim.json.decode, response)
    if ok then
      response = decoded
    else
      return {
        title = "Generated Task",
        description = response,
        difficulty = 3,
      }
    end
  end
  
  return {
    id = M.generate_task_id(),
    title = response.title or "Learning Task",
    description = response.description or "",
    starter_code = response.starter_code or "",
    expected_output = response.expected_output or "",
    hints = response.hints or {},
    difficulty = response.difficulty or 3,
    concepts = response.concepts or {},
    estimated_time = response.estimated_time or "15 minutes",
    created_at = os.time(),
  }
end

M.get_language_level = function(lang)
  local progress = require("vibelearn.data.progress")
  local lang_progress = progress.get_language_progress(lang)
  return lang_progress.proficiency or "beginner"
end

M.generate_task_id = function()
  local template = "task-xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format("%x", v)
  end)
end

M.review_code = function(lang, code, callback)
  local context = {
    language = lang,
    code = code,
    level = M.get_language_level(lang),
  }
  
  local prompt = M.build_prompt(prompts.CODE_REVIEW, context)
  
  M.query(prompt, context, function(result, err)
    if err then
      log.error("Failed to review code:", err)
      if callback then
        callback(nil, err)
      end
      return
    end
    
    local review = M.parse_review_response(result)
    
    if callback then
      callback(review, nil)
    end
  end)
end

M.parse_review_response = function(response)
  if not response then
    return nil
  end
  
  if type(response) == "string" then
    local ok, decoded = pcall(vim.json.decode, response)
    if ok then
      response = decoded
    else
      return {
        idiomatic_score = 5,
        improvements = { "Unable to parse AI response" },
        explanation = response,
      }
    end
  end
  
  return {
    idiomatic_score = response.idiomatic_score or 5,
    top_improvements = response.top_3_improvements or response.improvements or {},
    concept_explanation = response.concept_explanation or response.explanation or "",
    quality_level = M.score_to_quality(response.idiomatic_score),
  }
end

M.score_to_quality = function(score)
  if not score then
    return "unknown"
  end
  
  if score >= 9 then
    return "expert"
  elseif score >= 7 then
    return "advanced"
  elseif score >= 5 then
    return "intermediate"
  else
    return "beginner"
  end
end

M.get_hint = function(task_id, hint_number, callback)
  local storage = require("vibelearn.data.tasks")
  local task = storage.get_task(task_id)
  
  if not task or not task.hints or#task.hints < hint_number then
    if callback then
      callback(nil, "No hint available")
    end
    return
  end
  
  if callback then
    callback(task.hints[hint_number], nil)
  end
end

M.suggest_improvements = function(lang, code_context, callback)
  local context = {
    language = lang,
    code_context = code_context,
    level = M.get_language_level(lang),
  }
  
  local prompt = M.build_prompt(prompts.SUGGEST_IMPROVEMENTS, context)
  
  M.query(prompt, context, function(result, err)
    if err then
      log.error("Failed to get improvements:", err)
      if callback then
        callback(nil, err)
      end
      return
    end
    
    if callback then
      callback(result, nil)
    end
  end)
end

M.test_task = function()
  local test_prompt = "Hello, this is a test message. Please respond with 'OK' if you receive this."
  
  M.query(test_prompt, nil, function(result, err)
    if err then
      log.error("OpenCode test failed:", err)
      return false
    end
    
    log.info("OpenCode test successful:", result)
    return true
  end)
end

return M