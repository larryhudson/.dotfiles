return {
  {
    "nvim-neotest/neotest",
    keys = function()
      local neotest = require("neotest")
      return {
        {
          "<leader>tt",
          function()
            neotest.run.run()
          end,
          { desc = "Test - Debug nearest" },
        },
        {
          "<leader>dt",
          function()
            neotest.run.run({ strategy = "dap" })
          end,
          { desc = "Test - Debug nearest" },
        },
        {
          "<leader>df",
          function()
            neotest.run.run(vim.fn.expand("%"))
          end,
          { desc = "Test - Run file" },
        },
      }
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end
    end,
  },
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>dt",
        false,
      },
    },
  },
}
