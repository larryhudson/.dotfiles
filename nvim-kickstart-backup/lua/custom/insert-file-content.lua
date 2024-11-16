local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local insert_file_content = function(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  local filename = entry.path or entry.filename

  actions.close(prompt_bufnr)

  -- Read the content of the selected file
  local file_content = {}
  local f = io.open(filename, 'r')
  if f ~= nil then
    for line in f:lines() do
      table.insert(file_content, line)
    end
    f:close()
  end

  -- Insert the content at the cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, file_content)
end

return insert_file_content
