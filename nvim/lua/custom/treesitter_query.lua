local api = vim.api
local ts = vim.treesitter
local tsquery = vim.treesitter.query

local M = {}

-- Function to ensure a language parser is installed
local function ensure_parser_installed(lang)
  local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
  if not parser_config[lang] then
    print("Parser for language '" .. lang .. "' is not available.")
    return false
  end

  if not ts.language.require_language(lang, nil, true) then
    vim.cmd('TSInstall ' .. lang)
    return ts.language.require_language(lang, nil, true)
  end

  return true
end

-- Function to run tree-sitter query on a single file
function M.run_query(query_string, bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype) or 'query'

  if not ensure_parser_installed(lang) then
    print('Failed to install parser for language: ' .. lang)
    return
  end

  local parser = ts.get_parser(bufnr, lang)
  local query = tsquery.parse(lang, query_string)
  local tree = parser:parse()[1]
  local root = tree:root()

  return query:iter_captures(root, bufnr, 0, -1)
end

-- Function to highlight matches in the current buffer and show syntactic labels
function M.highlight_matches_with_labels(matches, bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local ns_id = api.nvim_create_namespace 'treesitter_query_highlight'
  api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  for id, node, metadata in matches do
    local start_row, start_col, end_row, end_col = node:range()

    -- Highlight the node
    api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
      end_line = end_row,
      end_col = end_col,
      hl_group = 'Search',
    })

    -- Add virtual text with the capture name (syntactic label)
    local capture_name = tsquery.get_capture_name(id)
    api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
      virt_text = { { capture_name, 'Comment' } },
      virt_text_pos = 'eol',
    })
  end
end

-- Function to create split windows for interactive query building
function M.create_query_builder()
  -- Create a new buffer for the query
  local query_bufnr = api.nvim_create_buf(false, true)
  vim.bo[query_bufnr].buftype = 'nofile'
  vim.bo[query_bufnr].bufhidden = 'hide'
  vim.bo[query_bufnr].filetype = 'query' -- Set filetype to 'query'
  api.nvim_buf_set_name(query_bufnr, 'Tree-sitter Query')

  -- Ensure the 'query' parser is installed
  ensure_parser_installed 'query'

  -- Split the window and set the query buffer on the left
  vim.cmd 'vsplit'
  api.nvim_win_set_buf(0, query_bufnr)

  -- Set up autocmd to run the query on buffer change
  api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer = query_bufnr,
    callback = function()
      local query_string = api.nvim_buf_get_lines(query_bufnr, 0, -1, false)[1]
      if query_string and query_string ~= '' then
        local matches = M.run_query(query_string)
        M.highlight_matches_with_labels(matches)
      end
    end,
  })

  -- Move cursor to the query window
  vim.cmd 'wincmd h'
end

-- Function to set keymaps
local function set_keymaps(mappings)
  for mode, mode_mappings in pairs(mappings) do
    for lhs, rhs in pairs(mode_mappings) do
      vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true })
    end
  end
end

-- Setup function to be called in user's init.lua
function M.setup(opts)
  opts = opts or {}

  -- Set up keymaps
  if opts.keymaps then
    set_keymaps(opts.keymaps)
  end

  -- Ensure the 'query' parser is installed during setup
  ensure_parser_installed 'query'

  -- Add any other configuration options here
end

-- Function to inspect the syntax tree
function M.inspect_tree()
  ts.inspect_tree()
end

-- Command to start the interactive query builder
api.nvim_create_user_command('TSQueryBuilder', function()
  M.create_query_builder()
end, {})

return M
