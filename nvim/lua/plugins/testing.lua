return {
  {
    "nvim-neotest/neotest",
    keys = {
      {
        "<leader>dt",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        {
          desc = "Test - Run nearest",
        },
      },
    },
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
