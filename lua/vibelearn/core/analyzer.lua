local M = {}
local log = require("vibelearn.utils.logger")
local history = require("vibelearn.data.history")
local progress = require("vibelearn.data.progress")

M.config = nil

M.SKILL_LEVELS = {
  beginner = 1,
  intermediate = 2,
  advanced = 3,
  expert = 4,
}

M.LEVEL_NAMES = {
  [1] = "beginner",
  [2] = "intermediate",
  [3] = "advanced",
  [4] = "expert",
}

M.init = function(cfg)
  M.config = cfg
end

M.assess_language = function(lang)
  local lang_progress = progress.get_language_progress(lang)
  local usage_stats = history.get_language_usage_stats(lang, 30)
  local error_patterns = history.get_error_patterns(lang, 10)
  
  local metrics = M.calculate_metrics(lang, lang_progress, usage_stats, error_patterns)
  local level = M.determine_level(metrics)
  local confidence = M.calculate_confidence(metrics)
  
  return {
    language = lang,
    level = level,
    confidence = confidence,
    metrics = metrics,
    strengths = M.identify_strengths(metrics),
    weaknesses = M.identify_weaknesses(metrics),
    recommendations = M.generate_recommendations(level, metrics),
  }
end

M.calculate_metrics = function(lang, lang_progress, usage_stats, error_patterns)
  local xp_level = M.xp_to_level(lang_progress.xp)
  local error_rate = M.calculate_error_rate(usage_stats)
  local time_spent = usage_stats.time_seconds / 3600
  local tasks_completed = lang_progress.tasks_completed
  local code_quality = M.estimate_code_quality(error_patterns)
  local learning_velocity = M.calculate_learning_velocity(lang_progress)
  
  return {
    xp_level = xp_level,
    error_rate = error_rate,
    time_spent_hours = time_spent,
    tasks_completed = tasks_completed,
    code_quality_score = code_quality,
    learning_velocity = learning_velocity,
    error_patterns_count = #error_patterns,
    consistency = M.calculate_consistency(usage_stats),
  }
end

M.xp_to_level = function(xp)
  if xp >= 5000 then
    return 4
  elseif xp >= 2000 then
    return 3
  elseif xp >= 500 then
    return 2
  else
    return 1
  end
end

M.calculate_error_rate = function(usage_stats)
  if usage_stats.switches == 0 then
    return 0
  end
  
  return usage_stats.errors_count / usage_stats.switches
end

M.estimate_code_quality = function(error_patterns)
  if #error_patterns == 0 then
    return 100
  end
  
  local severity_weights = {
    syntax = 1.0,
    type_error = 0.8,
    warning = 0.3,
    style = 0.1,
  }
  
  local total_penalty = 0
  for _, pattern in ipairs(error_patterns) do
    local weight = severity_weights[pattern.type] or 0.5
    total_penalty = total_penalty + (pattern.count * weight)
  end
  
  local quality_score = math.max(0, 100 - total_penalty)
  return quality_score
end

M.calculate_learning_velocity = function(lang_progress)
  if lang_progress.time_spent_minutes == 0 then
    return 0
  end
  
  local tasks_per_hour = lang_progress.tasks_completed / (lang_progress.time_spent_minutes / 60)
  return tasks_per_hour
end

M.calculate_consistency = function(usage_stats)
  if usage_stats.switches ==0 then
    return 0
  end
  
  return math.min(100, (usage_stats.switches / 30) * 100)
end

M.determine_level = function(metrics)
  local score = 0
  
  score = score + metrics.xp_level * 25
  
  score = score + (1 - metrics.error_rate) * 20
  
  score = score + math.min(metrics.time_spent_hours / 10, 1) * 20
  
  score = score + math.min(metrics.tasks_completed / 20, 1) *20
  
  score = score + (metrics.code_quality_score / 100) * 15
  
  if score >= 75 then
    return "expert"
  elseif score >= 50 then
    return "advanced"
  elseif score >= 25 then
    return "intermediate"
  else
    return "beginner"
  end
end

M.calculate_confidence = function(metrics)
  local data_points = 0
  
  if metrics.time_spent_hours > 0 then
    data_points = data_points + 1
  end
  
  if metrics.tasks_completed > 0 then
    data_points = data_points + 1
  end
  
  if metrics.error_patterns_count > 0 then
    data_points = data_points + 1
  end
  
  local consistency_factor = metrics.consistency / 100
  
  return math.min(1.0, (data_points / 3) *0.7 + consistency_factor * 0.3)
end

M.identify_strengths = function(metrics)
  local strengths = {}
  
  if metrics.error_rate < 0.1 then
    table.insert(strengths, "Low error rate - writing clean code")
  end
  
  if metrics.code_quality_score > 80 then
    table.insert(strengths, "High code quality")
  end
  
  if metrics.learning_velocity > 2 then
    table.insert(strengths, "Fast learning pace")
  end
  
  if metrics.consistency > 70 then
    table.insert(strengths, "Consistent practice")
  end
  
  if metrics.tasks_completed > 10 then
    table.insert(strengths, "Strong task completion record")
  end
  
  return strengths
end

M.identify_weaknesses = function(metrics)
  local weaknesses = {}
  
  if metrics.error_rate > 0.3 then
    table.insert(weaknesses, "High error rate - may need more foundational practice")
  end
  
  if metrics.code_quality_score < 50 then
    table.insert(weaknesses, "Code quality could be improved")
  end
  
  if metrics.time_spent_hours < 1 then
    table.insert(weaknesses, "Limited practice time")
  end
  
  if metrics.consistency < 30 then
    table.insert(weaknesses, "Irregular practice schedule")
  end
  
  if metrics.learning_velocity < 1 then
    table.insert(weaknesses, "Slow learning velocity - may benefit from different approach")
  end
  
  return weaknesses
end

M.generate_recommendations = function(level, metrics)
  local recommendations = {}
  
  if level == "beginner" then
    table.insert(recommendations, "Focus on syntax fundamentals")
    table.insert(recommendations, "Complete basic tutorials")
    table.insert(recommendations, "Practice with simple exercises")
  elseif level == "intermediate" then
    table.insert(recommendations, "Learn language-specific idioms")
    table.insert(recommendations, "Work on moderate complexity tasks")
    table.insert(recommendations, "Study best practices and patterns")
  elseif level == "advanced" then
    table.insert(recommendations, "Explore advanced language features")
    table.insert(recommendations, "Contribute to open-source projects")
    table.insert(recommendations, "Focus on performance and optimization")
  else
    table.insert(recommendations, "Consider mentoring others")
    table.insert(recommendations, "Explore niche areas of the language")
    table.insert(recommendations, "Stay updated with latest developments")
  end
  
  if metrics.error_rate > 0.2 then
    table.insert(recommendations, "Review error patterns and common mistakes")
  end
  
  if metrics.consistency < 50 then
    table.insert(recommendations, "Establish a regular practice schedule")
  end
  
  return recommendations
end

M.compare_languages = function(source_lang, target_lang)
  local source_assessment = M.assess_language(source_lang)
  local target_assessment = M.assess_language(target_lang)
  
  local knowledge_transfer = M.assess_knowledge_transfer(source_lang, target_lang)
  local learning_path = M.suggest_learning_path(source_assessment, target_assessment)
  
  return {
    source = source_assessment,
    target = target_assessment,
    knowledge_transfer = knowledge_transfer,
    learning_path = learning_path,
    difficulty_gap = M.calculate_difficulty_gap(source_assessment, target_assessment),
  }
end

M.assess_knowledge_transfer = function(source_lang, target_lang)
  local similar_languages = {
    python = { lua = 0.8, javascript = 0.6, ruby = 0.7, rust = 0.3 },
    javascript = { typescript = 0.9, python = 0.5, lua = 0.4, go = 0.4 },
    rust = { cpp = 0.7, go = 0.5, haskell = 0.4, python = 0.3 },
    go = { rust = 0.5, python = 0.4, javascript = 0.4, java = 0.6 },
    lua = { python = 0.7, javascript = 0.5, ruby = 0.6, rust = 0.2 },
  }
  
  if similar_languages[source_lang] and similar_languages[source_lang][target_lang] then
    return similar_languages[source_lang][target_lang]
  end
  
  return 0.4
end

M.suggest_learning_path = function(source_assessment, target_assessment)
  local path = {}
  
  table.insert(path, {
    step = 1,
    title = "Syntax foundations",
    description = "Learn basic syntax differences",
    duration = "1-2 hours",
  })
  
  table.insert(path, {
    step = 2,
    title = "Core concepts",
    description = "Understand fundamental language concepts",
    duration = "3-5 hours",
  })
  
  table.insert(path, {
    step = 3,
    title = "Idiomatic patterns",
    description = "Learn language-specific idioms and patterns",
    duration = "5-10 hours",
  })
  
  table.insert(path, {
    step = 4,
    title = "Best practices",
    description = "Study best practices and conventions",
    duration = "3-5 hours",
  })
  
  return path
end

M.calculate_difficulty_gap = function(source_assessment, target_assessment)
  local source_level = M.SKILL_LEVELS[source_assessment.level]
  local target_level = M.SKILL_LEVELS[target_assessment.level]
  
  return math.max(0, target_level - source_level)
end

M.get_next_difficulty = function(current_level)
  local level = M.SKILL_LEVELS[current_level] or 1
  
  if level >= 4 then
    return 5
  end
  
  return level + 1
end

M.should_suggest_challenge = function(lang)
  local assessment = M.assess_language(lang)
  local progress_data = progress.get_language_progress(lang)
  
  local recent_tasks = progress_data.tasks_completed or 0
  local success_rate = progress_data.success_rate or 0
  
  return recent_tasks >= 5 and success_rate > 0.7 and assessment.confidence > 0.5
end

M.get_recommended_concepts = function(lang, level)
  local concept_map = {
    beginner = {
      rust = { "ownership", "borrowing", "lifetimes", "structs", "enums" },
      go = { "goroutines", "channels", "interfaces", "goroutines", "defer" },
      python = { "lists", "dicts", "classes", "decorators", "generators" },
      javascript = { "promises", "async/await", "closures", "prototypes" },
    },
    intermediate = {
      rust = { "trait objects", "smart pointers", "concurrency", "error handling" },
      go = { "concurrency patterns", "testing", "reflection", "embedding" },
      python = { "metaclasses", "descriptors", "asyncio", "context managers" },
      javascript = { "proxies", "symbols", "generators", "modules" },
    },
    advanced = {
      rust = { "unsafe rust", "FFI", "macro_rules", "procedural macros" },
      go = { "unsafe", "cgo", "compiler internals", "runtime" },
      python = { "C extensions", "bytecode", "internals", "optimization" },
      javascript = { "engines", "optimizations", "webassembly", "ffi" },
    },
    expert = {
      rust = { "language design", "compiler contributions", "library design" },
      go = { "language proposals", "runtime contributions", "specification" },
      python = { "PEP contributions", "interpreter", "optimizations" },
      javascript = { "specification", "engine contributions", "tooling" },
    },
  }
  
  if concept_map[level] and concept_map[level][lang] then
    return concept_map[level][lang]
  end
  
  return {}
end

return M