return {
  'olrtg/nvim-emmet',
  config = function()
    vim.keymap.set({ 'n', 'v' }, '<leader>wa', require('nvim-emmet').wrap_with_abbreviation, { desc = '[W]rap with [A]bbreviation' })
  end,
}
