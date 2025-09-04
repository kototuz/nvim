vim.opt.guicursor = "n-v-sm:block,i-ve-t-c-ci:ver25,r-cr-o:hor20"
vim.opt.inccommand = "split"
vim.opt.hls = false
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.gdefault = true
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
vim.opt.list = true
vim.opt.listchars = { tab = "» ", lead = "⸱", trail = "⸱" }
vim.opt.laststatus = 3

vim.g.c_no_curly_error = true

vim.opt.tabline = "%!v:lua.PillTabline()"
function _G.PillTabline()
    local s = ""
    local tabs = vim.api.nvim_list_tabpages()
    local current = vim.api.nvim_get_current_tabpage()

    for i, tab in ipairs(tabs) do
        local is_active = (tab == current)
        local hl = is_active and "%#TabLine#" or "%#TabLineFill#"
        s = s .. hl .. " " .. i .. " " .. "%#TabLineFill#"
    end

    return s
end
