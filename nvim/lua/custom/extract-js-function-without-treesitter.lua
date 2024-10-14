local function read_tsconfig()
  local file = io.open('tsconfig.json', 'r')
  if not file then
    return nil
  end
  local content = file:read '*all'
  file:close()
  return vim.fn.json_decode(content)
end

local function resolve_alias(alias, tsconfig)
  local paths = tsconfig.compilerOptions.paths
  local base_url = tsconfig.compilerOptions.baseUrl or './'

  for key, value in pairs(paths) do
    local pattern = '^' .. key:gsub('%*', '(.+)')
    local match = alias:match(pattern)
    if match then
      local resolved_path = base_url .. '/' .. value[1]:gsub('%*', match)
      return resolved_path
    end
  end
  return nil
end

local function extract_js_function()
  if vim.bo.filetype ~= 'javascript' and vim.bo.filetype ~= 'typescript' then
    print 'Not a JavaScript/TypeScript file!'
    return
  end

  -- Get the first path alias from tsconfig
  local tsconfig = read_tsconfig()
  if not tsconfig then
    print 'Could not read tsconfig.json!'
    return
  end

  local first_alias = nil
  for key, _ in pairs(tsconfig.compilerOptions.paths) do
    first_alias = key:match '^([^*]*)'
    break
  end

  -- Save cursor position
  local cursor_position = vim.api.nvim_win_get_cursor(0)

  -- Get the line range of the selection
  local start_row = vim.fn.line "'<"
  local end_row = vim.fn.line "'>"

  -- Get the selected lines
  local lines = vim.fn.getline(start_row, end_row)
  local first_line = lines[1]
  print('First line of selection: ' .. first_line)

  -- Extract the function name using regex
  local function_name = first_line:match 'function%s+([%w_]+)%s*%('

  if not function_name then
    print 'Could not extract function name from the selected code!'
    return
  end

  local alias_prompt = 'Enter alias for the new JS filename: '

  local alias = vim.fn.input(alias_prompt, first_alias or '')
  if alias == '' then
    print 'Alias cannot be empty!'
    return
  end

  -- Print a newline character to move to the next line
  print ''

  local filepath = resolve_alias(alias, tsconfig)
  if not filepath then
    print 'Could not resolve alias!'
    return
  end

  local function_code = 'export ' .. table.concat(lines, '\n')
  local function_code_lines = vim.split(function_code, '\n')

  -- Ensure the directory exists
  local dirname = vim.fn.fnamemodify(filepath, ':h')
  vim.fn.mkdir(dirname, 'p')

  vim.fn.writefile(function_code_lines, filepath)

  -- Create import statement using the alias
  local import_statement = string.format("import { %s } from '%s';", function_name, alias)

  -- Insert import statement at the top of the file
  vim.api.nvim_buf_set_lines(0, 0, 0, false, { import_statement })

  -- Delete the selected lines silently
  vim.cmd "silent! '<,'>d"

  -- Restore cursor position
  vim.api.nvim_win_set_cursor(0, cursor_position)
end

_G.extract_js_function = extract_js_function
