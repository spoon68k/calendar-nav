# Calendar Navigator for Neovim

A lightweight Neovim plugin that provides a floating calendar navigator. With this plugin you can quickly jump to daily note files by selecting a day from a three‑month calendar view (previous, current, and next month). It’s designed to integrate nicely with Obsidian workflows or any daily note system.

## Features

- **Floating Calendar View:** Opens a centered floating window displaying three months.
- **Navigation:** The cursor automatically lands on today’s date. Use standard movement keys to select another date.
- **Quick File Opening:** Press `<CR>` (Enter) on a date to open the corresponding daily note (e.g. `dailies/2025-01-07.md`).
- **Easy Configuration:** Customize the directory for your daily notes and the float’s border style.

## Requirements

- **Neovim 0.5+**
- A Unix-like environment with the `cal` command installed.
- Lua (bundled with Neovim 0.5 and later)

## Installation with Lazy.nvim

Place this plugin in your Lazy configuration. For example, add the following to your `lua/plugins.lua` (or wherever you configure Lazy):

```lua
return {
  {
    "yourusername/calendar-nav", -- replace with the correct repository path
    config = function()
      require("calendar-nav").setup({
        dailies_dir = "my-dailies",  -- customize the daily notes directory
        border = "double",           -- customize the border style ("rounded", "single", "double", etc.)
      })
    end,
  },
}
```

Then, run :Lazy sync or restart Neovim to install the plugin.

## Configuration

Call the plugin’s setup() function from your Neovim configuration to override the default settings:

* `dailies_dir (string)`: The directory where your daily notes are stored. Default: "dailies"
* `border (string)`: The border style for the floating window. Default: "rounded"

Example:

```lua
require("calendar-nav").setup({
  dailies_dir = "my-dailies",
  border = "double",
})
```

## Usage

* **Open the Calendar**: Run the command :CalendarNav in Neovim. A floating window will appear showing three months.
* **Navigate**: The cursor will start on today’s date. Use arrow keys or hjkl to move around the calendar.
* **Open a Daily Note**: Press <CR> (Enter) on a day. The plugin will look up the corresponding date and open a file like my-dailies/YYYY-MM-DD.md in the current window.
* **Close the Calendar**: Press <Esc> or q to close the floating window without opening a file.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Contributing
Contributions, bug reports, and feature requests are welcome! Please open an issue or submit a pull request on GitHub.

## Acknowledgments
* Uses the Unix cal command to generate calendar output.
* Inspired by Obsidian’s daily note workflows.
