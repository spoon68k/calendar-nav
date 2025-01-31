local M = {}

-- Internal configuration (will be updated via M.configure)
M.config = {
  dailies_dir = "dailies",
  border = "rounded",
}

---------------------------
-- Helper Functions
---------------------------

-- Returns the weekday of the 1st day of the given month.
-- Monday = 1, …, Sunday = 7.
local function get_start_wday(year, month)
  local t = os.time({year = year, month = month, day = 1})
  local w = os.date("*t", t).wday  -- Lua: Sunday = 1, Monday = 2, …, Saturday = 7
  return ((w + 5) % 7) + 1
end

-- Returns the number of days in the given month.
local function days_in_month(year, month)
  local t = os.time({year = year, month = month + 1, day = 0})
  return os.date("*t", t).day
end

-- Runs "cal -3 -m --color=never" for the given month/year.
-- Returns a mapping table (mapping[row][col] → {year, month, day})
-- and a list of text lines (the cal output) to be shown in the float.
local function build_calendar_mapping(year, month)
  local cmd = string.format("cal -3 -m --color=never %d %d", month, year)
  local handle = io.popen(cmd)
  local cal_output = handle:read("*a")
  handle:close()
  local lines = vim.split(cal_output, "\n", { trimempty = true })

  -- We assume the output is an 8-row x 64-column grid.
  local total_rows = 8
  local total_cols = 64
  local mapping = {}
  for r = 1, total_rows do
    mapping[r] = {}
    for c = 1, total_cols do
      mapping[r][c] = nil
    end
  end

  -- Determine previous, current, and next month info.
  local prev_year, prev_month
  if month == 1 then
    prev_year = year - 1
    prev_month = 12
  else
    prev_year = year
    prev_month = month - 1
  end

  local cur_year, cur_month = year, month

  local next_year, next_month
  if month == 12 then
    next_year = year + 1
    next_month = 1
  else
    next_year = year
    next_month = month + 1
  end

  local blocks = {
    { start_col = 1,  end_col = 20, year = prev_year, month = prev_month },
    { start_col = 23, end_col = 42, year = cur_year,  month = cur_month },
    { start_col = 45, end_col = 64, year = next_year, month = next_month },
  }

  -- For each block (each month) fill in the day numbers.
  for _, block in ipairs(blocks) do
    local block_start = block.start_col
    local byear = block.year
    local bmonth = block.month
    local start_wday = get_start_wday(byear, bmonth)
    local dim = days_in_month(byear, bmonth)

    -- The day grid is printed in rows 3 to 8.
    for week = 1, 6 do
      local overall_row = week + 2
      for dow = 1, 7 do  -- dow: Monday (1) ... Sunday (7)
        local cell_index = (week - 1) * 7 + dow
        local day = cell_index - start_wday + 1
        if day >= 1 and day <= dim then
          local col_in_block
          if dow == 1 then
            col_in_block = 1
          elseif dow == 2 then
            col_in_block = 4
          elseif dow == 3 then
            col_in_block = 7
          elseif dow == 4 then
            col_in_block = 10
          elseif dow == 5 then
            col_in_block = 13
          elseif dow == 6 then
            col_in_block = 16
          elseif dow == 7 then
            col_in_block = 19
          end
          -- Each day number is printed in a 2-character field.
          for offset = 0, 1 do
            local overall_col = block_start + col_in_block - 1 + offset
            mapping[overall_row][overall_col] = { year = byear, month = bmonth, day = day }
          end
        end
      end
    end
  end

  return mapping, lines
end

---------------------------
-- Public API
---------------------------

-- Allows the parent module to configure options.
function M.configure(config)
  M.config = vim.tbl_deep_extend("force", M.config, config or {})
end

-- Opens the floating calendar and sets up keymaps.
function M.open_calendar_nav()
  local today = os.date("*t")
  local mapping, lines = build_calendar_mapping(today.year, today.month)

  -- Create a scratch buffer.
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Compute window size based on the cal output.
  local win_height = #lines
  local win_width = 64
  local opts = {
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = (vim.o.lines - win_height) / 2 - 1,
    col = (vim.o.columns - win_width) / 2,
    style = 'minimal',
    border = M.config.border,  -- use configured border type
  }
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Map <Esc> and "q" to close the floating window.
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>close<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<CR>', { noremap = true, silent = true })

  -- Map <CR> (Return) to check the mapping table at the current cursor position
  -- and open the corresponding daily file.
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '', {
    nowait = true,
    noremap = true,
    silent = true,
    callback = function()
      local pos = vim.api.nvim_win_get_cursor(win)  -- returns {row, col} (col is 0-indexed)
      local row = pos[1]
      local col = pos[2] + 1  -- convert to 1-indexed
      local cell = mapping[row] and mapping[row][col]
      if cell then
        local filepath = string.format("%s/%04d-%02d-%02d.md", M.config.dailies_dir, cell.year, cell.month, cell.day)
        vim.api.nvim_win_close(win, true)
        vim.cmd("edit " .. filepath)
      else
        vim.notify("Not a valid date", vim.log.levels.INFO)
      end
    end,
  })

  -- Position the cursor on today's date.
  local target_row, target_col
  for r = 1, #mapping do
    for c = 1, #mapping[r] do
      local cell = mapping[r][c]
      if cell and cell.year == today.year and cell.month == today.month and cell.day == today.day then
        target_row = r
        target_col = c - 1  -- win_set_cursor expects a 0-indexed column.
        break
      end
    end
    if target_row then break end
  end
  if target_row and target_col then
    vim.api.nvim_win_set_cursor(win, { target_row, target_col })
  end
end

return M

