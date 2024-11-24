local dapui_config = {
  icons = { expanded = '', collapsed = '', current_frame = '' },
  mappings = {
    -- Use a table to apply multiple mappings
    expand = { '<CR>', '<2-LeftMouse>' },
    open = 'o',
    remove = 'd',
    edit = 'e',
    repl = 'r',
    toggle = 't',
  },
  element_mappings = {},
  expand_lines = vim.fn.has 'nvim-0.7' == 1,
  force_buffers = true,
  layouts = {
    {
      -- You can change the order of elements in the sidebar
      elements = {
        -- Provide IDs as strings or tables with "id" and "size" keys
        -- {
        --   id = 'scopes',
        --   size = 0.25, -- Can be float or integer > 1
        -- },
        { id = 'watches', size = 0.8 },
        { id = 'breakpoints', size = 0.2 },
        -- { id = 'stacks', size = 0.25 },
      },
      size = 40,
      position = 'left', -- Can be "left" or "right"
    },
    {
      elements = {
        'console',
      },
      size = 15,
      position = 'bottom', -- Can be "bottom" or "top"
    },
  },
  floating = {
    max_height = nil,
    max_width = nil,
    border = 'single',
    mappings = {
      ['close'] = { 'q', '<Esc>' },
    },
  },
  controls = {
    enabled = vim.fn.exists '+winbar' == 1,
    element = 'repl',
    icons = {
      pause = '',
      play = '',
      step_into = '',
      step_over = '',
      step_out = '',
      step_back = '',
      run_last = '',
      terminate = '',
      disconnect = '',
    },
  },
  render = {
    max_type_length = nil, -- Can be integer or nil.
    max_value_lines = 100, -- Can be integer or nil.
    indent = 1,
  },
}

return {
  {
    'nvim-neotest/nvim-nio',
  },
  {
    'rcarriga/nvim-dap-ui',
    dependencies = 'mfussenegger/nvim-dap',
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'
      dapui.setup(dapui_config)
      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open()
      end
      -- dap.listeners.before.event_terminated['dapui_config'] = function()
      --   dapui.close()
      -- end
      -- dap.listeners.before.event_exited['dapui_config'] = function()
      --   dapui.close()
      -- end
      vim.keymap.set('n', '<leader>dc', function()
        dap.continue()
      end, { desc = '[D]AP - [C]ontinue' })
      vim.keymap.set('n', '<leader>ds', function()
        dap.step_over()
      end, { desc = '[D]AP - [S]tep Over' })
      vim.keymap.set('n', '<F7>', function()
        dap.step_into()
      end, { desc = 'DAP - Step Into' })
      vim.keymap.set('n', '<F8>', function()
        dap.step_out()
      end, { desc = 'DAP - Step Out' })
      vim.keymap.set('n', '<leader>dr', function()
        dap.run_last()
      end, { desc = '[D]AP - [R]e-run Last' })
      vim.keymap.set('n', '<leader>b', function()
        dap.toggle_breakpoint()
      end, { desc = 'DAP - Toggle [B]reakpoint' })
      vim.keymap.set('n', '<leader>do', function()
        dapui.open()
      end, { desc = '[D]AP - [O]pen UI' })
      vim.keymap.set('n', '<leader>dx', function()
        dapui.close()
      end, { desc = '[D]AP - E[x]it UI' })
    end,
  },
  {
    'mfussenegger/nvim-dap',
  },
  {
    'mfussenegger/nvim-dap-python',
    ft = 'python',
    dependencies = {
      'mfussenegger/nvim-dap',
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',
    },
    config = function(_, opts)
      local path = '~/.local/share/nvim/mason/packages/debugpy/venv/bin/python'
      local dap_python = require 'dap-python'
      dap_python.setup(path)
      dap_python.test_runner = 'pytest'
    end,
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/neotest-python',
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      -- Determine python path - prefer poetry/virtualenv over system
      local function get_python_path()
        local venv = vim.fn.getcwd() .. '/.venv/bin/python'
        local poetry = vim.fn.getcwd() .. '/poetry.lock'

        if vim.fn.filereadable(poetry) == 1 then
          return vim.fn.system('poetry env info -p'):gsub('\n', '') .. '/bin/python'
        elseif vim.fn.filereadable(venv) == 1 then
          return venv
        else
          return vim.fn.exepath 'python3' or vim.fn.exepath 'python'
        end
      end

      require('neotest').setup {
        adapters = {
          require 'neotest-python' {
            dap = {
              justMyCode = false,
              -- Use debugpy's python for debugging but project's python for running tests
              python = '~/.local/share/nvim/mason/packages/debugpy/venv/bin/python',
            },
            -- Use project's python for running tests
            python = get_python_path(),
          },
        },
      }

      vim.keymap.set('n', '<leader>td', function()
        require('neotest').run.run { strategy = 'dap' }
      end, { desc = 'DAP - Test method' })
    end,
  },
  {
    'theHamsta/nvim-dap-virtual-text',
    config = function()
      require('nvim-dap-virtual-text').setup {
        virt_text_pos = 'inline',
      }
    end,
  },
  {
    'williamboman/mason.nvim',
    opts = {
      ensure_installed = {
        'black',
        'debugpy',
        'mypy',
        'ruff-lsp',
        'pyright',
      },
    },
  },
}
