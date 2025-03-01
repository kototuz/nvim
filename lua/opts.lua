vim.keymap.set("i", "<C-c>", "<Esc>")

-- vim.opt.guicursor = "n-v-i-c:block-Cursor"
vim.opt.guicursor = ""

vim.opt.inccommand = "split"

vim.opt.hls = false
vim.opt.smartcase = true
vim.opt.incsearch = true

vim.opt.number = true
vim.opt.rnu = true

vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.swapfile = false

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.formatoptions:remove "o"

vim.opt.showcmd = true
vim.opt.scrolloff = 10
vim.opt.updatetime = 50
vim.opt.wrap = false

vim.cmd[[
hi CursorLineNr guifg=#af00af
set cursorline
set cursorlineopt=number
]]

vim.g.netrw_banner = 0
vim.g.netrw_localcopydircmd = "cp -r"
vim.g.netrw_list_hide = "\\(^\\|\\s\\s\\)\\zs\\.\\S\\+"
vim.g.netrw_keepdir = false
vim.g.netrw_bufsettings = 'noma nomod nu rnu nobl nowrap ro'

vim.g.c_no_curly_error = true

vim.opt.list = true
vim.opt.listchars = {
    -- leadmultispace = "│   ",
    -- space = "·",
    tab = "» ",
}
