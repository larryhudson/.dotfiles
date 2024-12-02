return {
  "nvim-telescope/telescope.nvim",
  keys = function(_, keys)
    local telescope_builtin = require("telescope.builtin")
    return vim.list_extend(keys, {
      { "<leader>sf", telescope_builtin.find_files, desc = "[S]earch [F]iles" },
      { "<leader>s.", telescope_builtin.oldfiles, desc = "[S]earch recent files" },
      { "<leader>ws", telescope_builtin.lsp_dynamic_workspace_symbols, desc = "LSP [W]orkspace [S]ymbols" },
      { "<leader>ds", telescope_builtin.lsp_document_symbols, desc = "LSP [D]ocument [S]ymbols" },
      { "<leader><Space>", telescope_builtin.buffers, desc = "Open Buffers" },
      { "<leader>gs", false },
    })
  end,
}
