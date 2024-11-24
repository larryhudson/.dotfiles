return {
  {
    dir = '/Users/larryhudson/.dotfiles/nvim/lua/custom/plugins/vim_motion_coach',
    name = 'vim_motion_coach',
    enabled = false,
    config = function()
      print 'Loading vim-language-coach'
      require('vim_motion_coach').setup {
        -- Any configuration options you want to add
      }
    end,
    event = 'CmdlineEnter', -- Load when entering command mode
    dependencies = {
      'rcarriga/nvim-notify', -- For better notifications
    },
  },
}
