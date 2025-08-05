return {
    {
        "metalelf0/black-metal-theme-neovim",
        lazy = false,
        priority = 1000,
        config = function()
            require("black-metal").setup {
                theme = "taake",
                variant = "dark",
                transparent = true,
                code_style = {
                    comments = "none"
                },
                highlights = {
                    ["@punctuation.bracket"] = { fg = "$fg" },
                    ["@constructor.lua"]     = { fg = "$fg" }
                }
            }

            require("black-metal").load()
        end
    },
}
