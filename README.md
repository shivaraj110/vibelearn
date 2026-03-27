# VibeLearn

**AI-Powered Language Learning for Neovim**

VibeLearn is a Neovim plugin that helps you transition from one programming language to another using AI-driven task generation, smart activity tracking, and gamified learning.

## Features

- **Intelligent Activity Tracking**: Monitors your coding patterns across languages
  - Filetype switches and time spent per language
  - LSP diagnostics and error pattern analysis
  - Git commit history analysis
  
- **AI-Powered Task Generation**: Creates personalized learning tasks based on:
  - Your current skill level in target languages
  - Common patterns from your source language
  - Progressive difficulty scaling
  
- **Gamification System**:
  - XP and leveling system
  - Achievement badges
  - Daily streaks
  - Progress visualization
  
- **OpenCode Integration**: Leverages OpenCode CLI for AI capabilities
  - Contextual task generation
  - Code review and feedback
  - Progressive hints system
  
- **Interactive Dashboard**: Built with Nui.nvim
  - Progress tracking
  - Language proficiency levels
  - Task management
  - Statistics and insights

## Requirements

- **Neovim** >= 0.9.0 (tested withv0.11.6)
- **Git**
- **OpenCode CLI** (for AI features)
- **Required plugins** (automatically installed):
  - [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
  - [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "shivaraj110/vibelearn",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("vibelearn").setup({
      -- Your configuration here (optional)
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "shivaraj110/vibelearn",
  requires = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("vibelearn").setup()
  end,
}
```

## Quick Start

1. **Install the plugin** using your plugin manager

2. **Install OpenCode CLI** (required for AI features):
   ```bash
   # See: https://github.com/opencode/opencode
   opencode --version
   ```

3. **Open Neovim and run**:
   ```vim
   :VibeLearn
   ```
   This opens the interactive dashboard.

4. **Get a learning task**:
   ```vim
   :VibeLearnTask
   ```

5. **Check health**:
   ```vim
   :VibeLearnHealth
   ```

## Configuration

```lua
require("vibelearn").setup({
  -- Languages
  source_language = "python",          -- Your primary language
  target_languages = { "rust", "go" }, -- Languages to learn
  
  -- Task Scheduling
  schedule = {
    on_filetype_switch = true,         -- Suggest tasks when switching languages
    idle_time_minutes = 5,              -- Wait before suggesting tasks
    daily_goal_tasks = 3,               -- Number of tasks per day goal
    reminder_interval_hours = 2,        -- Time between reminders
  },
  
  -- Gamification
  gamification = {
    enabled = true,
    show_notifications = true,
    celebrate_achievements = true,
    streak_reminders = true,
    xp_multiplier = 1.0,
  },
  
  -- OpenCode Settings
  opencode = {
    model = "opencode-go/minimax-m2.7",
    context_lines = 100,
    timeout_seconds = 30,
  },
  
  -- Dashboard UI
  dashboard = {
    position = "right",
    width = 60,
    height = 80,
    border = "rounded",
  },
  
  -- Tracking
  tracking = {
    filetypes = { enabled = true, min_time_seconds = 30 },
    lsp = { enabled = true, track_errors = true, track_warnings = true },
    git = { enabled = true, commit_analysis = true },
  },
  
  -- Storage
  storage = {
    data_path = vim.fn.stdpath("data") .. "/vibelearn",
    backup_enabled = true,
    max_history_days = 30,
  },
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:VibeLearn` | Open the interactive dashboard |
| `:VibeLearnTask` | Get a new learning task |
| `:VibeLearnStats` | View your statistics |
| `:VibeLearnReset` | Reset all progress |
| `:VibeLearnHealth` | Run health check |

## Keymaps

Default keymaps (configurable):

```lua
vim.keymap.set("n", "<leader>vl", "<cmd>VibeLearn<cr>", { desc = "Open VibeLearn Dashboard" })
vim.keymap.set("n", "<leader>vs", "<cmd>VibeLearnTask<cr>", { desc = "Start a Task" })
```

Dashboard keymaps:
- `q` - Close dashboard
- `<CR>` - Start selected task
- `s` - Skip current task
- `r` - Refresh dashboard

## How It Works

1. **Activity Tracking**:
   - Tracks which languages you work with
   - Monitors time spent per language
   - Analyzes error patterns via LSP
   - Reviews git commits

2. **Skill Assessment**:
   - Evaluates your proficiency level (beginner → expert)
   - Identifies strengths and improvement areas
   - Tracks learning velocity

3. **Task Generation**:
   - AI creates personalized tasks
   - Building on known concepts
   - Progressive difficulty
   - Contextual to your work

4. **Gamification**:
   - Earn XP for completing tasks
   - Unlock achievements
   - Maintain daily streaks
   - Visualize progress

## Data Storage

VibeLearn stores data locally in:
```
~/.local/share/nvim/vibelearn/
├── profile.json      # Your profile & preferences
├── progress.json     # XP, levels, achievements
├── history.json      # Activity timeline
└── tasks/            # Task cache & history
```

## Dashboard Preview

```
╔════════════════════════════════════════════════════════════╗
║                    VibeLearn Dashboard                      ║
╠════════════════════════════════════════════════════════════╣

  Welcome, Developer

  Learning: rust, go, typescript
  Streak: 3 days (longest: 7)

╠════════════════════════════════════════════════════════════╣
║                      Progress                               ║
╠════════════════════════════════════════════════════════════╣

  Level: 5
  XP: 1250
  Tasks Completed: 42
  Languages: 3
  Time: 12.5 hours

╠════════════════════════════════════════════════════════════╣
║                      Actions                                 ║
╠════════════════════════════════════════════════════════════╣

  [t] Get new task
  [s] View statistics
  [r] Refresh dashboard
  [q] Close

╚════════════════════════════════════════════════════════════╝
```

**Task Display:**
```
╔════════════════════════════════════════════════════════════╗
║ Create a simple struct with methods                          ║
╠════════════════════════════════════════════════════════════╣

  Language: Rust
  Difficulty: ★★☆☆☆
  Time: 15 minutes

  Description:
    Learn Rust's struct syntax and method implementation
    by creating a basic Rectangle struct.

  Concepts:
    - Struct definition
    - Method syntax
    - Self keyword

╠════════════════════════════════════════════════════════════╣
  [Enter] Start Task
  [h] View Hints
  [s] Skip Task
  [q] Close
╚════════════════════════════════════════════════════════════╝
```

## Roadmap

- [ ] Interactive code exercises
- [ ] Language-specific learning paths
- [ ] Team/leaderboard features
- [ ] Export progress reports
- [ ] Integration with more AI providers
- [ ] Custom task templates

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development

```bash
# Clone the repository
git clone https://github.com/shivaraj110/vibelearn.git
cd vibelearn

# Run tests
make test

# Run linting
make lint

# Install dependencies locally
make install
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Created by **Shivaraj**
- GitHub: [@shivaraj110](https://github.com/shivaraj110)

Built with:
- [Neovim](https://neovim.io/)
- [Nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [OpenCode](https://github.com/opencode)

## Support

If you find this plugin helpful, consider giving it a ⭐ on GitHub!

For issues, questions, or suggestions:
- [GitHubIssues](https://github.com/shivaraj110/vibelearn/issues)
- [GitHub Discussions](https://github.com/shivaraj110/vibelearn/discussions)