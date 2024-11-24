return {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    lazy = false,
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    opts = {
      view_options = {
        show_hidden = true,
      },
    },
    keys = {
      { "-", "<CMD>Oil<CR>", { desc = "Open parent directory " } },
    },
  },
}
