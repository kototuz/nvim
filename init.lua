vim.g.mapleader = " "

require("config.lazy")

vim.opt.listchars = { space = "·" }
vim.opt.list = true
vim.api.nvim_set_hl(0, "Whitespace", { fg="#252525" })
vim.cmd[[ highlight Type gui=bold ]]

vim.keymap.set("i", "<C-c>", "<Esc>")
vim.opt.guicursor = "n-v-i-c:block-Cursor"
vim.opt.hls = false
vim.opt.number = true
vim.opt.rnu = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.swapfile = false
vim.opt.shiftwidth = 4 
vim.opt.tabstop = 4
vim.opt.smartcase = true
vim.opt.showcmd = true

vim.g.c_no_curly_error = true
