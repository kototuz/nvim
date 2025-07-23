return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        require("telescope").setup({
            defaults = {
                mappings = {
                    i = {
                        ["<C-j>"] = "select_default",
                    }
                }
            },
        })

        local builtin = require("telescope.builtin")
        vim.keymap.set('n', '<leader>f', builtin.find_files, {})
        vim.keymap.set('n', '<leader>/', builtin.live_grep, {})
        vim.keymap.set('n', '<leader>b', builtin.buffers, {})
    end
}
