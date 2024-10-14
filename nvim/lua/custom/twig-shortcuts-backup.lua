-- Extract nested props from a string like "items[name,url]"
local function extract_nested_props(prop)
  print('extract_nested_props - prop: ' .. prop)
  local array_name = string.match(prop, '([^%[]+)')
  print('array_name: ' .. array_name)
  local array_items = string.match(prop, '%[(.-)%]')
  if array_items then
    print('array_items: ' .. array_items)
    local array_props = vim.fn.split(array_items, ',')
    for i, array_prop in ipairs(array_props) do
      array_props[i] = vim.fn.trim(array_prop)
      print('array_prop[' .. i .. ']: ' .. array_props[i])
    end
    return array_name, array_props
  else
    print('Error: Could not extract array items from prop: ' .. prop)
    return array_name, {}
  end
end

--
-- Utility function to process the props string
-- Example input: "heading, items[name,url]"
-- Output:
-- {
--   "{{ include('partials/MyComponent', {",
--   "  heading: '',",
--   "  items: [",
--   "    { name: '',",
--   "      url: '' },",
--   "  ],",
--   "}) }}"
-- }

local function process_props_string(props_string, filename)
  local include_lines = { string.format("{{ include('partials/%s', {", filename) }
  local props = vim.fn.split(props_string, ',')

  for _, prop in ipairs(props) do
    prop = vim.fn.trim(prop)
    print('process_props_string - prop: ' .. prop)
    if string.match(prop, '%[') then
      local array_name, array_props = extract_nested_props(prop)
      table.insert(include_lines, string.format('  %s: [', array_name))
      table.insert(include_lines, '    {')
      for _, array_prop in ipairs(array_props) do
        table.insert(include_lines, string.format("      %s: '',", array_prop))
      end
      table.insert(include_lines, '    },')
      table.insert(include_lines, '  ],')
    else
      table.insert(include_lines, string.format("  %s: '',", prop))
    end
  end

  table.insert(include_lines, '}) }}')
  return include_lines
end

-- Utility function to add {% for %} loops for array props
-- Example input: "items[name,url]"
-- Adds:
-- {% for item in items %}
-- {# Available props: items.name, items.url #}
-- {% endfor %}
local function add_for_loops(component_lines, props_string)
  local props = vim.fn.split(props_string, ',')

  for _, prop in ipairs(props) do
    prop = vim.fn.trim(prop)
    print('add_for_loops - prop: ' .. prop)
    if string.match(prop, '%[') then
      local array_name, array_props = extract_nested_props(prop)

      -- Construct the {% for %} loop
      table.insert(component_lines, string.format('{%% for item in %s %%}', array_name))
      local available_props = 'Available props: '
      for i, array_prop in ipairs(array_props) do
        if i > 1 then
          available_props = available_props .. ', '
        end
        available_props = available_props .. string.format('%s.%s', array_name, array_prop)
      end
      table.insert(component_lines, string.format('{# %s #}', available_props))
      table.insert(component_lines, '{% endfor %}')
    end
  end

  return component_lines
end

function ExtractTwigTemplate()
  if vim.bo.filetype ~= 'twig' then
    print 'Not a Twig file!'
    return
  end

  local function get_filename()
    local filename = vim.fn.input 'Enter new template filename: '
    if filename == '' then
      print 'Filename cannot be empty!'
      return nil
    end

    local filepath = 'templates/partials/' .. filename .. '.twig'
    while vim.fn.filereadable(filepath) == 1 do
      local overwrite = vim.fn.input 'File already exists. Do you want to override it? (y/N): '
      if overwrite:lower() == 'y' then
        break
      else
        filename = vim.fn.input 'Enter new template filename: '
        if filename == '' then
          print 'Filename cannot be empty!'
          return nil
        end
        filepath = 'templates/partials/' .. filename .. '.twig'
      end
    end
    return filename, filepath
  end

  local filename, filepath = get_filename()
  if not filename then
    return
  end

  local comment = vim.fn.input 'Enter a comment (optional): '
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  local component_lines = vim.fn.getline(start_line, end_line)

  if type(component_lines) == 'string' then
    component_lines = { component_lines }
  end

  if comment ~= '' then
    table.insert(component_lines, 1, '{# ' .. comment .. ' #}')
  end

  local props_string = vim.fn.input 'Enter a list of properties, separated by commas, or skip to leave blank: '
  local include_lines

  if props_string ~= '' then
    include_lines = process_props_string(props_string, filename)
    component_lines = add_for_loops(component_lines, props_string)
    local props_line_for_component = '{# Available props: ' .. props_string .. ' #}'
    table.insert(component_lines, 1, props_line_for_component)
  else
    include_lines = { string.format("{{ include('partials/%s') }}", filename) }
  end

  vim.fn.writefile(component_lines, filepath)

  -- Get leading whitespace from the first selected line
  local first_line = vim.fn.getline(start_line)
  local leading_whitespace = first_line:match '^%s*'

  -- Delete the selected lines and insert the include statement with leading whitespace
  vim.cmd "'<,'>d"

  for _, line in ipairs(include_lines) do
    vim.fn.append(start_line - 1, leading_whitespace .. line)
    start_line = start_line + 1
  end

  -- Ask if the user wants to open the new component file
  local open_file = vim.fn.input 'Do you want to open the new component file? (y/N): '
  if open_file:lower() == 'y' then
    vim.cmd('edit ' .. filepath)
  end
end

vim.api.nvim_set_keymap('x', '<Leader>et', ':lua ExtractTwigTemplate()<CR>', { noremap = true, silent = true })

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
