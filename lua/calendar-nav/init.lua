local M = {}
local calendar = require("calendar-nav.calendar")

-- Default configuration (override via setup if desired)
M.default_config = {
  dailies_dir = "dailies",  -- path or relative directory for daily notes
  border = "rounded",       -- e.g. "single", "double", "rounded", etc.
}

function M.setup(opts)
  local config = vim.tbl_deep_extend("force", M.default_config, opts or {})
  -- Pass the configuration on to the calendar module.
  calendar.configure(config)

  -- Create a user command that opens the calendar float.
  vim.api.nvim_create_user_command("CalendarNav", function()
    calendar.open_calendar_nav()
  end, {})
end

return M

