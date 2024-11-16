return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    -- add svelte
    vim.list_extend(opts.ensure_installed, {
      "svelte",
      "astro",
    })
  end,
}
