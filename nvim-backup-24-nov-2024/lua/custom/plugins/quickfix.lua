return {
  {
    'kevinhwang91/nvim-bqf',
    enabled = true,
    config = function()
      require('bqf').setup()
    end,
  },
  {
    'stevearc/qf_helper.nvim',
    opts = {},
  },
}
