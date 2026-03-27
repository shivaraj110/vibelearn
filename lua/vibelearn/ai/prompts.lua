local M = {}

M.GENERATE_TASK = [[
You are an expert programming educator specializing in teaching language transitions. Generate a practical coding task for someone learning a new programming language.

Source Language: {{source_lang}} (User's expertise level: {{source_level}})
Target Language: {{target_lang}} (User's learning level: {{target_level}})
Difficulty: {{difficulty}} (scale of 1-5, where 1 is beginner)
Focus Areas: {{focus_areas}}

USER CONTEXT:
- The user is proficient in {{source_lang}}
- They want to learn {{target_lang}}
- They are currently at {{target_level}} level in {{target_lang}}

Create a practical, hands-on coding exercise that:
1. Builds on concepts familiar from {{source_lang}}
2. Introduces key {{target_lang}} concepts progressively
3. Provides real-world context and practical application
4. Includes starter code to guide the learner
5. Defines clear success criteria and expected output
6. Offers progressive hints for stuck learners
7. Estimates time to complete

Respond with ONLY a JSON object (no markdown, no code blocks) with this structure:

{
  "title": "Clear, engaging task title",
  "description": "Detailed task description explaining what to build and why it matters",
  "starter_code": "// Well-commented starter code showing the structure\n// Include TODO comments for user to fill in",
  "expected_output": "What the successful solution should produce or accomplish",
  "hints": [
    "First hint: gentle nudge in right direction",
    "Second hint: more specific guidance",
    "Third hint: nearly complete solution approach"
  ],
  "difficulty": 3,
  "concepts": ["concept1", "concept2", "concept3"],
  "estimated_time": "15 minutes",
  "prerequisites": ["concept from {{source_lang}} that helps"],
  "learning_objectives": ["objective1", "objective2"]
}

Make the task engaging, practical, and appropriately challenging for someone at the {{target_level}} level.
]]

M.CODE_REVIEW = [[
You are a code quality expert specializing in {{language}}. Analyze this code from a learning perspective for someone at the {{level}} level.

Language: {{language}}
User Level: {{level}}

Code to Review:
```
{{code}}
```

Provide constructive feedback that helps the learner improve their {{language}} skills. Focus on:
- Language-specific idioms and best practices
- Common mistakes learners make
- How to make the code more {{language}}-idiomatic

Respond with ONLY a JSON object (no markdown, no code blocks):

{
  "idiomatic_score": 7,
  "top_3_improvements": [
    "Specific improvement with example",
    "Another improvement with context",
    "Third most important improvement"
  ],
  "concept_explanation": "Clear explanation of key {{language}} concepts demonstrated",
  "positive_aspects": ["What they did well"],
  "next_steps": ["What to practice next"]
}

Score the code from1-10 where:
- 1-3: Beginner code with common patterns from other languages
- 4-6: Functional but could be more idiomatic
- 7-8: Good use of language features
- 9-10: Expert-level, highly idiomatic and idiomatic
]]

M.SUGGEST_IMPROVEMENTS = [[
You are a programming language coach helping someone transition to {{language}}. They are currently at {{level}} level.

Language: {{language}}
Current Level: {{level}}
Code Context:
{{code_context}}

Suggest 3-5 specific, actionable improvements the learner can make to become more proficient in {{language}}.

Focus on:
- Language-specific patterns and idioms
- Best practices for {{language}}
- Common pitfalls to avoid
- Progressive skill development

Respond with ONLY a JSON array (no markdown):

[
  {
    "area": "Syntax/Pattern/Best Practice",
    "current": "What they're doing now",
    "suggested": "More idiomatic approach",
    "example": "Code example showing the improvement",
    "benefit": "Why this matters in {{language}}",
    "difficulty": 2
  }
]

Rate difficulty from 1 (beginner) to 5 (expert).
]]

M.EXPLAIN_CONCEPT = [[
You are an expert programming educator. Explain a {{language}} concept to someone transitioning from {{source_lang}}.

Source Language (what they know): {{source_lang}}
Target Language (what they're learning): {{target_lang}}
Concept to Explain: {{concept}}
User's Level in {{target_lang}}: {{level}}

Provide a clear, engaging explanation that:
1. Relates the concept to something familiar in {{source_lang}}
2. Explains how and why it's different or similar
3. Provides practical examples with comparisons
4. Offers tips for remembering and applying the concept

Structure your response as:
- **Analogous Concept** (from {{source_lang}})
- **Key Differences**
- **Practical Example** (comparing both)
- **Common Pitfalls**
- **Pro Tips**

Keep explanations clear but not patronizing. Aim for someone who is intelligent and motivated to learn.
]]

M.GENERATE_HINT = [[
A learner is stuck on a coding task in {{language}}. Provide a helpful hint that guides without solving.

Language: {{language}}
Task Description: {{task_description}}
User's Current Code:
{{user_code}}
Attempt Number: {{attempt_number}}

Generate hint #{{hint_number}} that:
- For hint 1: Gives a gentle nudge in the right direction
- For hint 2: Provides more specific guidance
- For hint 3: Shows the approach without giving away the answer

Respond with ONLY plain text (no JSON, no formatting):

Your hint should be encouraging and educational, not just giving the answer.
]]

M.ASSESS_SKILL = [[
Assess a developer's skill level in {{language}} based on their recent coding activity.

Language: {{language}}
Error Patterns: {{error_patterns}}
Code Complexity Metrics: {{complexity_metrics}}
Time Spent: {{time_spent}}
Tasks Completed: {{tasks_completed}}
Recent Errors Count: {{error_count}}

Determine their proficiency level:
- beginner: Frequent basic syntax errors, unfamiliar with idioms
- intermediate: Can write working code, some idiomatic usage
- advanced: Strong grasp of idioms, few errors, optimization awareness
- expert: Exceptional code quality, mentoring-level knowledge

Provide ONLY a JSON object (no markdown):

{
  "level": "intermediate",
  "confidence": 0.75,
  "strengths": ["strength1", "strength2"],
  "areas_for_improvement": ["area1", "area2"],
  "recommended_tasks": ["task type1", "task type2"]
}
]]

M.CREATE_LEARNING_PATH = [[
Create a personalized learning path for transitioning from {{source_lang}} to{{target_lang}}.

Source Language: {{source_lang}} (User expertise: {{source_level}})
Target Language: {{target_lang}} (User level: {{target_level}})
User's Goals: {{goals}}
Available Time: {{time_available}}
Preferred Difficulty: {{difficulty_preference}}

Create a progressive learning path with 5-10 stepping stones that:
- Start with concepts familiar from {{source_lang}}
- Gradually introduce {{target_lang}}-specific concepts
- Build practical skills incrementally
- Include practice exercises for each step
- Provide realistic time estimates

Respond with ONLY a JSON array (no markdown):

[
  {
    "step": 1,
    "title": "Step Title",
    "concepts": ["concept1", "concept2"],
    "prerequisites": ["What you need before this step"],
    "exercises": ["practice exercise 1", "practice exercise 2"],
    "estimated_time": "2-3 hours",
    "milestones": ["complete understanding of X", "able to doY"]
  }
]

Order steps from most foundational to most advanced.
]]

return M