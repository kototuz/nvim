return {
    -- {
    --     "sainnhe/gruvbox-material",
    --     config = function()
    --         vim.g.gruvbox_material_enable_italic = false
    --         vim.g.gruvbox_material_background = "hard"
    --         vim.g.gruvbox_material_float_style = "dim"
    --         vim.g.gruvbox_material_disable_italic_comment = true
    --         vim.cmd.colorscheme("gruvbox-material")
    --     end
    -- },
    {
        "vague-theme/vague.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("vague").setup({
                italic = false,
            })
            vim.cmd("colorscheme vague")
        end
    },
}
