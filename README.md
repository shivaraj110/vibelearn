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

- **Neovim** >= 0.9.0
- **OpenCode CLI** installed and configured
- **Required plugins** (automatically installed):
  - [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
  - [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "shivaraj/vibelearn",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("vibelearn").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "shivaraj/vibelearn",
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

1. **Install the plugin** using your preferred plugin manager

2. **Configure OpenCode CLI**:
   ```bash
   # Install OpenCode CLI
   # See: https://github.com/opencode/opencode
   
   # Verify installation
   opencode --version
   ```

3. **Open Neovim and run**:
   ```vim
   :VibeLearn
   ```
   This opens the interactive dashboard.

4. **Set your learning goals**:
   ```vim
   :VibeLearnTask
   ```
   Get personalized learning tasks.

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
  },
  
  -- OpenCode Settings
  opencode = {
    model = "opencode-go/minimax-m2.7",
    context_lines = 100,
    timeout_seconds =30,
  },
  
  -- Dashboard UI
  dashboard = {
    position = "right",
    width = 60,
    height = 80,
    border = "rounded",
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

## Keymaps

Default keymaps (configurable):

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>vl` | Normal | Open VibeLearn dashboard |
| `<leader>vs` | Normal | Start a new task |
| `q` | Dashboard | Close dashboard |
| `<CR>` | Dashboard | Start selected task |
| `s` | Dashboard | Skip current task |
| `r` | Dashboard | Refresh dashboard |

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

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Created by **Shivaraj**
- GitHub: [@shivaraj](https://github.com/shivaraj)

Built with:
- [Neovim](https://neovim.io/)
- [Nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [OpenCode](https://github.com/opencode)

## Support

If you find this plugin helpful, consider giving it a ⭐ on GitHub!

For issues, questions, or suggestions:
- [GitHub Issues](https://github.com/shivaraj/vibelearn/issues)
- [GitHub Discussions](https://github.com/shivaraj/vibelearn/discussions)