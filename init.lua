vim.pack.add({
    { src = "https://github.com/nvim-lua/plenary.nvim", version = "v0.1.4" },
    { src = "https://github.com/nvim-telescope/telescope.nvim", version = "v0.2.2" },

    "https://github.com/tpope/vim-fugitive",
    "https://github.com/echasnovski/mini.operators",
    "https://github.com/echasnovski/mini.surround",
    "https://github.com/echasnovski/mini.align",
    "https://github.com/vague-theme/vague.nvim",
    "https://github.com/kototuz/simple.nvim"
})

require("vague").setup({ italic = false })
vim.cmd.colorscheme("vague")

require("mini.surround").setup()
require("mini.operators").setup()
require("mini.align").setup()

require("telescope").setup({
    defaults = {
        mappings = {
            i = {
                ["<C-j>"] = "select_default",
                ["<C-u>"] = false,
            }
        }
    },
})

require("opts")
require("keymaps")

require("simple").setup({
    shell_command = {
        telescope_opts = require("telescope.themes").get_dropdown{}
    }
})
