local lpeg = vim.lpeg

-- Define patterns using LPeg
local C, Ct, P, R, S = lpeg.C, lpeg.Ct, lpeg.P, lpeg.R, lpeg.S

-- Helper pattern to trim whitespace
local space = S ' \t\n' ^ 0

-- Patterns for parsing properties
local word = C((R('az', 'AZ', '09') + S '_-') ^ 1)
local nested_props = P '[' * C((1 - P ']') ^ 0) * P ']'

local prop = Ct(word * (nested_props + P ''))
local props = Ct((prop * (space * P ',' * space * prop) ^ 0))

-- Parse props string using LPeg
local function parse_props_string(props_string)
  -- print('Parsing props_string:', props_string)
  local parsed_props = props:match(props_string)
  -- print('Parsed props:', vim.inspect(parsed_props))
  local result = {}

  for _, prop in ipairs(parsed_props) do
    local name, nested = prop[1], prop[2]
    -- print('Prop name:', name, 'Nested:', nested)
    if nested and nested ~= '' then
      local nested_trimmed = {}
      for _, nested_prop in ipairs(vim.fn.split(nested, ',')) do
        table.insert(nested_trimmed, vim.fn.trim(nested_prop))
      end
      -- print('Extracted nested:', table.concat(nested_trimmed, ', '))
      table.insert(result, { name = name, nested = nested_trimmed })
    else
      table.insert(result, { name = name })
    end
  end

  -- print('Final parsed result:', vim.inspect(result))
  return result
end

-- Extract nested props function
local function extract_nested_props(prop)
  -- print('extract_nested_props - prop: ' .. prop.name)
  if prop.nested then
    -- print('nested props: ' .. table.concat(prop.nested, ', '))
    return prop.name, prop.nested
  end
  return prop.name, {}
end

-- Get singular form of array name
local function get_singular_name(array_name)
  if array_name:sub(-1) == 's' then
    return array_name:sub(1, -2)
  end
  return 'item'
end

-- Updated process_props_string function using LPeg parsing
local function process_props_string(props_string, filename)
  local include_lines = { string.format("{{ include('partials/%s', {", filename) }
  local parsed_props = parse_props_string(props_string)

  for _, prop in ipairs(parsed_props) do
    if prop.nested then
      local array_name, array_props = extract_nested_props(prop)
      table.insert(include_lines, string.format('  %s: [', array_name))
      table.insert(include_lines, '    {')
      for _, array_prop in ipairs(array_props) do
        table.insert(include_lines, string.format("      %s: '',", vim.fn.trim(array_prop)))
      end
      table.insert(include_lines, '    },')
      table.insert(include_lines, '  ],')
    else
      table.insert(include_lines, string.format("  %s: '',", prop.name))
    end
  end

  table.insert(include_lines, '}) }}')
  return include_lines
end

-- Updated add_for_loops function using LPeg parsing
local function add_for_loops(props_string)
  local parsed_props = parse_props_string(props_string)
  local for_lines = {}

  for _, prop in ipairs(parsed_props) do
    if prop.nested then
      local array_name, array_props = extract_nested_props(prop)
      local singular_name = get_singular_name(array_name)

      -- Construct the {% for %} loop
      table.insert(for_lines, string.format('{%% for %s in %s %%}', singular_name, array_name))
      for _, array_prop in ipairs(array_props) do
        table.insert(for_lines, string.format("{%% set %s = %s.%s ?? '' %%}", array_prop, singular_name, array_prop))
      end
      table.insert(for_lines, '{% endfor %}')
      table.insert(for_lines, '')
    end
  end

  return for_lines
end

-- Updated add_set_statements function
local function add_set_statements(props_string)
  local parsed_props = parse_props_string(props_string)
  local set_lines = {}

  for _, prop in ipairs(parsed_props) do
    if prop.nested then
      table.insert(set_lines, string.format('{%% set %s = %s ?? [] %%}', prop.name, prop.name))
    else
      table.insert(set_lines, string.format("{%% set %s = %s ?? '' %%}", prop.name, prop.name))
    end
  end

  table.insert(set_lines, '')
  return set_lines
end

-- Updated ExtractTwigTemplate function
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
    local set_lines = add_set_statements(props_string)
    local for_lines = add_for_loops(props_string)
    local new_component_lines = {}

    for _, line in ipairs(set_lines) do
      table.insert(new_component_lines, line)
    end
    for _, line in ipairs(for_lines) do
      table.insert(new_component_lines, line)
    end
    for _, line in ipairs(component_lines) do
      table.insert(new_component_lines, line)
    end
    component_lines = new_component_lines

    include_lines = process_props_string(props_string, filename)
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
