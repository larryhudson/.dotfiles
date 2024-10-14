function HandleTwigComponentCss()
  local current_file = vim.fn.expand '%:p'
  local filename = vim.fn.fnamemodify(current_file, ':t:r')
  local component_css_path = 'src/css/components/' .. filename .. '.css'
  local main_css_path = 'src/css/components.css'

  -- Check if SCSS file exists
  if vim.fn.filereadable(component_css_path) == 1 then
    -- If it exists, open it
    vim.cmd('edit ' .. component_css_path)
  else
    -- If it doesn't exist, create the SCSS file
    vim.fn.writefile({}, component_css_path)

    -- Add import statement to main.css
    local import_statement = '@import "./components/' .. filename .. '";'
    local main_css_lines = vim.fn.readfile(main_css_path)

    -- Check if the use statement is already present
    local found = false
    for _, line in ipairs(main_css_lines) do
      if line == import_statement then
        found = true
        break
      end
    end

    if not found then
      table.insert(main_css_lines, import_statement)
      vim.fn.writefile(main_css_lines, main_css_path)
    end

    -- Open the new component CSS file
    vim.cmd('edit ' .. component_css_path)
  end
end

vim.api.nvim_set_keymap('n', '<Leader>cs', ':lua HandleTwigComponentCss()<CR>', { noremap = true, silent = true })
