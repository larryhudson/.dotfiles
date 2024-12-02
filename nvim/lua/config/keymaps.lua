-- Function to open a terminal in a bottom split
local function open_bottom_term(cmd, opts)
  opts = opts or {}
  local height = math.floor(vim.o.lines * (opts.height or 0.2))

  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Open a new split at the bottom with our buffer
  vim.cmd("botright " .. height .. "split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  if cmd and not opts.prefill then
    -- Execute command immediately
    vim.fn.termopen(string.format("%s && $SHELL", cmd), {
      on_exit = function()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end)
      end,
    })
  else
    -- Open terminal with just the shell
    vim.fn.termopen(vim.o.shell, {
      on_exit = function()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end)
      end,
    })

    -- If prefill is true, send the command without executing
    if cmd and opts.prefill then
      vim.api.nvim_chan_send(vim.b.terminal_job_id, cmd)
    end
  end

  -- Set buffer options
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = "no"
  vim.opt_local.buflisted = false

  -- Start in terminal mode
  vim.cmd("startinsert")

  -- Add ESC mapping to exit terminal mode
  vim.keymap.set("t", "<ESC>", [[<C-\><C-n>]], { buffer = true })

  -- Add mapping to close terminal
  vim.keymap.set("n", "q", ":close<CR>", { buffer = true })
end

vim.keymap.set("n", "<leader>gb", function()
  open_bottom_term("gh pr create --fill-verbose", { prefill = true })
end)
