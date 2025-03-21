vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data")
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(vim.fn.stdpath("data"))

require("keymaps")
require("opts")
require("term")
require("run")

vim.cmd("hi LineNr ctermbg=NONE guibg=NONE")
require("lazy").setup(
    { import = "plugins" },
    { change_detection = { notify = false } }
)
