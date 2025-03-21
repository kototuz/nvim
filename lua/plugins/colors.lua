return {
    {
        "vague2k/vague.nvim",
        config = function()
            require("vague").setup({
                transparent = true
            })
        end
    },
    {
        "echasnovski/mini.base16", version = '*',
        config = function()
            require("mini.base16").setup({
                palette = {
                    base00 = "#000000",
                    base01 = "#000000",
                    base02 = "#222222",
                    base03 = "#333333",
                    base04 = "#999999",
                    base05 = "#c1c1c1",
                    base06 = "#999999",
                    base07 = "#c1c1c1",
                    base08 = "#5f8787",
                    base09 = "#aaaaaa",
                    base0A = "#8c7f70",
                    base0B = "#9b8d7f",
                    base0C = "#aaaaaa",
                    base0D = "#888888",
                    base0E = "#999999",
                    base0F = "#444444",
                },
            })
        end
    },
}
