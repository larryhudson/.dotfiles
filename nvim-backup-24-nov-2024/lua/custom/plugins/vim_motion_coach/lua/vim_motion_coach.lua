-- plugin/vim_language_coach.lua
local M = {}

M.debug = {
  enabled = true, -- Set to false to disable debug logs
  logs = {},
  log = function(msg)
    if M.debug.enabled then
      table.insert(M.debug.logs, {
        timestamp = os.time(),
        message = msg,
      })
    end
  end,
  show_logs = function()
    if #M.debug.logs == 0 then
      vim.notify('No debug logs found', vim.log.levels.INFO)
      return
    end
    local lines = { 'VimLanguageCoach Debug Logs:' }
    for _, log in ipairs(M.debug.logs) do
      table.insert(lines, string.format('%s: %s', os.date('%H:%M:%S', log.timestamp), log.message))
    end
    vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
  end,
}

-- Command component definitions with educational descriptions
M.verbs = {
  d = {
    name = 'delete',
    description = 'Remove text and store in register',
  },
  y = {
    name = 'yank',
    description = 'Copy text into register',
  },
  c = {
    name = 'change',
    description = 'Delete text and enter insert mode',
  },
  v = {
    name = 'visual select',
    description = 'Start visual selection',
  },
}

M.modifiers = {
  a = {
    name = 'around',
    description = 'Include delimiters/whitespace',
  },
  i = {
    name = 'inside',
    description = 'Inside delimiters',
  },
  t = {
    name = 'till',
    description = 'Up to character',
  },
  f = {
    name = 'find',
    description = 'Move to character',
  },
}

M.objects = {
  w = {
    name = 'word',
    description = 'A word',
  },
  W = {
    name = 'WORD',
    description = 'A WORD (space-separated)',
  },
  s = {
    name = 'sentence',
    description = 'A sentence',
  },
  p = {
    name = 'paragraph',
    description = 'A paragraph',
  },
  ['{'] = {
    name = 'curly block',
    description = 'A {} block',
  },
  ['('] = {
    name = 'parentheses',
    description = 'A () block',
  },
  ['['] = {
    name = 'square brackets',
    description = 'A [] block',
  },
  ["'"] = {
    name = 'single quotes',
    description = "Text in ''",
  },
  ['"'] = {
    name = 'double quotes',
    description = 'Text in ""',
  },
  t = {
    name = 'tag',
    description = 'An HTML/XML tag',
  },
}

M.movements = {
  j = 'down',
  k = 'up',
  h = 'left',
  l = 'right',
  w = 'word forward',
  b = 'word backward',
  ['0'] = 'start of line',
  ['$'] = 'end of line',
  ['{'] = 'paragraph up',
  ['}'] = 'paragraph down',
  ['gg'] = 'file start',
  ['G'] = 'file end',
}

-- Store patterns to encourage
M.patterns = {
  -- Each pattern has preferred and discouraged forms
  -- along with explanations of why one is better
}

-- Track command history with timestamps and context
M.history = {}

-- Educational messages explaining the "vim language" concept
M.language_tips = {
  'Think of commands as sentences: verb (d/y/c) + modifier (a/i) + object (w/s/p/{)',
  "Movements can be objects! 'd}' means 'delete to next paragraph'",
  "Search patterns are movements too: 'd/foo' deletes until 'foo'",
  "Text objects are powerful: 'ci\"' changes inside quotes",
  "Markers create movements: 'ma' sets mark 'a', 'd`a' deletes to mark",
  'The dot command (.) repeats the last change',
  "Registers are like variables: \"ay yanks to register 'a'",
}

-- Function to analyze a command's grammar
function M.analyze_grammar(command)
  local analysis = {
    verb = nil,
    modifier = nil,
    object = nil,
    movement = nil,
    register = nil,
    count = nil,
    explanation = {},
  }

  -- Extract count prefix
  local count = command:match '^(%d+)'
  if count then
    analysis.count = tonumber(count)
    command = command:gsub('^%d+', '')
  end

  -- Extract register
  local reg = command:match '^"(.)'
  if reg then
    analysis.register = reg
    command = command:gsub('^".$', '')
  end

  -- Extract verb
  local first_char = command:sub(1, 1)
  if M.verbs[first_char] then
    analysis.verb = first_char
    table.insert(analysis.explanation, string.format('Using %s (%s)', M.verbs[first_char].name, M.verbs[first_char].description))
    command = command:sub(2)
  end

  -- Extract modifier
  local next_char = command:sub(1, 1)
  if M.modifiers[next_char] then
    analysis.modifier = next_char
    table.insert(analysis.explanation, string.format('with modifier %s (%s)', M.modifiers[next_char].name, M.modifiers[next_char].description))
    command = command:sub(2)
  end

  -- Extract object/movement
  if command:len() > 0 then
    local obj = command:sub(1, 1)
    if M.objects[obj] then
      analysis.object = obj
      table.insert(analysis.explanation, string.format('on %s (%s)', M.objects[obj].name, M.objects[obj].description))
    elseif M.movements[obj] then
      analysis.movement = obj
      table.insert(analysis.explanation, string.format('with movement %s', M.movements[obj]))
    end
  end

  return analysis
end

-- Function to suggest more idiomatic alternatives
function M.suggest_improvement(analysis)
  local suggestions = {}

  -- Check for common anti-patterns
  if analysis.verb == 'v' and analysis.modifier == nil then
    table.insert(suggestions, {
      what = 'Using visual mode for simple operations',
      why = 'Direct operator commands are often more efficient',
      instead = string.format("Try using '%s' directly", analysis.object and analysis.object or 'appropriate operator'),
    })
  end

  -- Check for opportunities to use text objects
  if analysis.movement and not analysis.modifier then
    local possible_object = M.objects[analysis.movement]
    if possible_object then
      table.insert(suggestions, {
        what = 'Using movement where text object exists',
        why = 'Text objects are more precise and semantic',
        instead = string.format("Try 'i%s' or 'a%s' (%s)", analysis.movement, analysis.movement, possible_object.description),
      })
    end
  end

  return suggestions
end

-- Record and analyze a command
function M.record_command(command)
  local analysis = M.analyze_grammar(command)

  -- Store in history with context
  table.insert(M.history, {
    command = command,
    analysis = analysis,
    timestamp = os.time(),
    suggestions = M.suggest_improvement(analysis),
  })

  -- Show educational feedback
  -- if #analysis.explanation > 0 then
  --   M.show_notification('Command breakdown: ' .. table.concat(analysis.explanation, ' '), 'info')
  -- end

  -- -- Show improvement suggestions
  -- for _, suggestion in ipairs(analysis.suggestions) do
  --   M.show_notification(string.format('%s\nWhy? %s\n%s', suggestion.what, suggestion.why, suggestion.instead), 'warn')
  -- end

  -- -- Occasionally show language tips
  -- if math.random() < 0.1 then -- 10% chance
  --   M.show_notification('Vim Tip: ' .. M.language_tips[math.random(#M.language_tips)], 'info')
  -- end
end

function M.timestamp()
  return os.date('%H:%M:%S', os.time())
end

function M.notify(message)
  vim.notify(M.timestamp() .. message, vim.log.levels.INFO)
end

function M.show_notification(message, level)
  vim.notify(message, vim.log.levels[string.upper(level)], {
    title = 'Vim Language Coach',
    timeout = 5000, -- Longer timeout for educational messages
  })
end

-- Get command statistics and patterns
function M.get_stats()
  local stats = {
    verbs = {},
    modifiers = {},
    objects = {},
    movements = {},
    patterns = {},
  }

  for _, entry in ipairs(M.history) do
    local a = entry.analysis
    if a.verb then
      stats.verbs[a.verb] = (stats.verbs[a.verb] or 0) + 1
    end
    if a.modifier then
      stats.modifiers[a.modifier] = (stats.modifiers[a.modifier] or 0) + 1
    end
    if a.object then
      stats.objects[a.object] = (stats.objects[a.object] or 0) + 1
    end
    if a.movement then
      stats.movements[a.movement] = (stats.movements[a.movement] or 0) + 1
    end

    -- Track common command patterns
    local pattern = table.concat({ a.verb, a.modifier, a.object }, '')
    stats.patterns[pattern] = (stats.patterns[pattern] or 0) + 1
  end

  return stats
end

-- State for tracking current command
M.command_state = {
  buffer = '', -- Stores keypresses for current command
  start_pos = nil, -- Starting cursor position
  mode = '', -- Current mode when command started
}

-- Reset the command state
function M.reset_command_state()
  M.command_state.buffer = ''
  M.command_state.start_pos = nil
  M.command_state.mode = ''
end

-- Start tracking a new command
function M.start_command()
  M.debug.log 'Starting command: '
  M.command_state.start_pos = vim.api.nvim_win_get_cursor(0)
  M.command_state.mode = vim.api.nvim_get_mode().mode
end

function M.process_command()
  -- Schedule the processing to happen after any pending keypresses
  vim.schedule(function()
    if M.command_state.buffer == '' then
      return
    end

    local cmd = M.command_state.buffer
    M.debug.log('Processing command: ' .. cmd)
    M.notify('Processing command: ' .. cmd)

    -- Record the command
    M.record_command(cmd)

    -- Reset state
    M.reset_command_state()
  end)
end

function M.handle_keypress(key)
  if key == nil then
    return key
  end

  local mode = vim.api.nvim_get_mode().mode
  M.debug.log(string.format('Keypress: %s (mode: %s)', key, mode))

  -- Ignore special keys
  if key:len() > 1 then
    return key
  end

  -- Start command if this is the first keypress
  if M.command_state.buffer == '' then
    M.command_state.start_pos = vim.api.nvim_win_get_cursor(0)
    M.command_state.mode = mode
  end

  M.command_state.buffer = M.command_state.buffer .. key

  -- Return the key to allow the command to execute normally
  return key
end

-- Setup function
function M.setup(opts)
  M.debug.log 'Starting VimLanguageCoach setup...'
  opts = opts or {}

  -- Define modes to track
  local modes = {
    'n', -- Normal mode
    'o',
    'v',
    'x',
    's',
  }

  -- Create expression mappings for all relevant keys
  local keys_to_map = {}

  -- Add numbers for counts
  for i = 0, 9 do
    table.insert(keys_to_map, tostring(i))
  end

  -- Add all ASCII letters (both cases)
  for i = 65, 90 do -- A-Z
    table.insert(keys_to_map, string.char(i))
    table.insert(keys_to_map, string.char(i + 32)) -- a-z
  end

  -- Add special characters used in Vim commands
  local special_chars = {
    '"',
    "'",
    '`',
    '[',
    ']',
    '{',
    '}',
    '(',
    ')',
    '<',
    '>',
    ',',
    '.',
    ';',
    ':',
    '/',
    '?',
    '\\',
    '|',
    '=',
    '-',
    '_',
    '+',
    '!',
    '@',
    '#',
    '$',
    '%',
    '^',
    '&',
    '*',
  }

  for _, char in ipairs(special_chars) do
    table.insert(keys_to_map, char)
  end

  -- Create mappings for each key in each mode
  for _, mode in ipairs(modes) do
    for _, key in ipairs(keys_to_map) do
      -- Escape special characters in the key
      local escaped_key = key:gsub('[%[%]%(%)%{%}%*%+%-%?%^%$%%]', '%%%1')

      -- Skip certain mappings in command mode
      if mode == 'c' and (key == '<' or key == '>' or key == '|') then
        goto continue
      end

      -- Create expression mapping
      vim.keymap.set(mode, key, function()
        M.debug.log('Key pressed: ' .. key)
        return M.handle_keypress(key)
      end, { expr = true })

      ::continue::
    end
  end

  -- Create the augroup
  local group = vim.api.nvim_create_augroup('VimLanguageCoach', { clear = true })
  M.debug.log 'Created augroup'

  -- Track text changes
  vim.api.nvim_create_autocmd('TextChanged', {
    group = group,
    pattern = '*',
    callback = function()
      M.notify 'TextChanged triggered!'
      M.debug.log 'Autocmd TextChanged'
      vim.defer_fn(function()
        M.process_command()
      end, 10)
      M.process_command()
    end,
  })

  -- Track cursor movements
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    pattern = '*',
    callback = function()
      M.notify 'CursorMoved triggered!'
      M.debug.log 'CursorMoved event'
      vim.defer_fn(function()
        M.process_command()
      end, 10)
    end,
  })

  -- Track yank operations
  vim.api.nvim_create_autocmd('TextYankPost', {
    group = group,
    callback = function()
      M.debug.log(string.format('TextYankPost - processing command: %s', M.command_state.buffer))
      vim.defer_fn(function()
        M.process_command()
      end, 10)
    end,
  })

  -- Track mode changes
  -- vim.api.nvim_create_autocmd('ModeChanged', {
  --   group = group,
  --   pattern = '*:*',
  --   callback = function()
  --     local from_mode = vim.v.event.old_mode
  --     local to_mode = vim.v.event.new_mode
  --     vim.notify(string.format('ModeChanged: %s -> %s', from_mode, to_mode), vim.log.levels.INFO)
  --     M.debug.log(string.format('ModeChanged event: %s -> %s', from_mode, to_mode))

  --     -- Only process command when:
  --     -- 1. Coming from operator-pending mode ('no') back to normal mode ('n')
  --     -- 2. Leaving visual mode ('v', 'V', '\x16') to normal mode
  --     -- 3. Leaving command mode ('c')
  --     -- 4. NOT when entering operator-pending mode
  --     if
  --       (from_mode == 'no' and to_mode == 'n') -- Completed operator command
  --       or (from_mode:match '^[vV\x16]' and to_mode == 'n') -- Leaving visual mode
  --       or (from_mode == 'c') -- Leaving command mode
  --       or (from_mode == 'n' and to_mode ~= 'no') -- Normal mode changes except to operator-pending
  --     then
  --       M.process_command()
  --     end
  --   end,
  -- })

  -- Create user commands
  -- Log configuration
  M.debug.log 'Creating user commands...'

  vim.api.nvim_create_user_command('VimLanguageStats', function()
    M.debug.log 'Showing statistics...'
    local stats = M.get_stats()
    local lines = {
      'Vim Language Usage Statistics:',
      '\nMost used verbs:',
    }

    for verb, count in pairs(stats.verbs) do
      table.insert(lines, string.format('  %s (%s): %d times', verb, M.verbs[verb].name, count))
    end

    table.insert(lines, '\nMost used modifiers:')
    for mod, count in pairs(stats.modifiers) do
      table.insert(lines, string.format('  %s (%s): %d times', mod, M.modifiers[mod].name, count))
    end

    table.insert(lines, '\nMost used movements:')
    for mov, count in pairs(stats.movements) do
      table.insert(lines, string.format('  %s (%s): %d times', mov, M.movements[mov], count))
    end

    table.insert(lines, '\nMost used patterns:')
    for pattern, count in pairs(stats.patterns) do
      table.insert(lines, string.format('  %s: %d times', pattern, count))
    end

    vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
  end, {
    desc = 'Show Vim language usage statistics',
  })

  -- Add debug command
  vim.api.nvim_create_user_command('VimLanguageDebug', function()
    M.debug.show_logs()
  end, {
    desc = 'Show VimLanguageCoach debug logs',
  })

  -- Test command to verify the plugin is loaded
  vim.api.nvim_create_user_command('VimLanguageTest', function()
    vim.notify(
      'VimLanguageCoach is loaded and running!\n' .. 'Plugin version: 1.0.0\n' .. 'Number of tracked commands: ' .. #(M.history or {}),
      vim.log.levels.INFO,
      {
        title = 'VimLanguageCoach Test',
        timeout = 3000,
      }
    )
  end, {
    desc = 'Test if VimLanguageCoach is working',
  })

  -- Add a test autocmd to verify group is working
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    pattern = '*',
    callback = function()
      vim.notify('BufEnter triggered!', vim.log.levels.INFO)
      M.debug.log 'BufEnter event'
    end,
  })

  M.debug.log 'Autocmd test setup complete'

  -- Print active autocmds in the group
  local autocmds = vim.api.nvim_get_autocmds { group = 'VimLanguageCoach' }
  for _, autocmd in ipairs(autocmds) do
    M.debug.log(string.format('Registered autocmd: %s', vim.inspect(autocmd)))
  end

  M.debug.log 'Setup complete!'
end

return M
