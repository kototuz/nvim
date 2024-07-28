local lazypath = vim.fn.stdpath("data")
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(vim.fn.stdpath("data"))

require("lazy").setup({
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                background = {
                    light = "latte",
                    dark = "mocha"
                }
            })

            -- vim.cmd("colorscheme catppuccin")
        end
    },
    {
        "rebelot/kanagawa.nvim",
        priority = 1000,
        config = function()
            vim.cmd("colorscheme kanagawa-dragon")
        end
    },
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("telescope").setup({
                defaults = {
                    mappings = {
                        i = {
                            ["<C-j>"] = "select_default"
                        }
                    }
                }
            })

            local builtin = require("telescope.builtin")
            vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
            vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
            vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
            vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
        end
    },
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local harpoon = require("harpoon")

            harpoon:setup()

            vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
            vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

            vim.keymap.set("n", "<C-1>", function() harpoon:list():select(1) end)
            vim.keymap.set("n", "<C-2>", function() harpoon:list():select(2) end)
            vim.keymap.set("n", "<C-3>", function() harpoon:list():select(3) end)
            vim.keymap.set("n", "<C-4>", function() harpoon:list():select(4) end)

            -- Toggle previous & next buffers stored within Harpoon list
            vim.keymap.set("n", "<C-p>", function() harpoon:list():prev() end)
            vim.keymap.set("n", "<C-n>", function() harpoon:list():next() end)
        end
    },
    {
        "mg979/vim-visual-multi",
        init = function()
            vim.g.VM_default_mappings = 0
            vim.g.VM_add_cursor_at_pos_no_mappings = 1
            vim.g.VM_maps = {
                ["Find Under"]      = "<C-d>",
                ["Exit"]            = "<C-c>",
                ["Add Cursor Down"] = "<C-j>",
                ["Add Cursor Up"]   = "<C-k>"
            }
        end
    }
})
