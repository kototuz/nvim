vim.keymap.set("n", "-", ":Oil<CR>")

vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")

vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

vim.keymap.set("n", "J", "mzJ`z")

vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "n", "nzzzv")

vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set("i", "<C-e>", "<End>")
vim.keymap.set({ "c", "i" }, "<C-a>", "<Home>")
vim.keymap.set({ "c", "i" }, "<C-f>", "<Right>")
vim.keymap.set({ "c", "i" }, "<C-b>", "<Left>")
vim.keymap.set({ "c", "i" }, "<M-b>", "<S-Left>")
vim.keymap.set({ "c", "i" }, "<M-f>", "<S-Right>")

vim.keymap.set("n", "<M-,>", "<c-w>5>")
vim.keymap.set("n", "<M-.>", "<c-w>5<")
vim.keymap.set("n", "<M-t>", "<c-w>+")
vim.keymap.set("n", "<M-s>", "<c-w>-")

vim.cmd[[
    au FileType netrw nmap <buffer> h -
    au FileType netrw nmap <buffer> l <CR>
]]
