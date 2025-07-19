vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<leader>x", ":.lua<CR>")
vim.keymap.set("v", "<leader>x", ":lua<CR>")

vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

vim.keymap.set("n", "<C-u>", "<c-u>zz")
vim.keymap.set("n", "<C-d>", "<c-d>zz")

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

vim.keymap.set("n", "<C-w>.", "<C-w>5>")
vim.keymap.set("n", "<C-w>,", "<C-w>5<")
vim.keymap.set("n", "<C-w>e", "<C-w>+")
vim.keymap.set("n", "<C-w>d", "<C-w>-")
vim.keymap.set("n", "<C-w><C-e>", "<C-w>+")
vim.keymap.set("n", "<C-w><C-d>", "<C-w>-")

vim.keymap.set("n", "<leader>1", ":tabn 1<CR>")
vim.keymap.set("n", "<leader>2", ":tabn 2<CR>")
vim.keymap.set("n", "<leader>3", ":tabn 3<CR>")
vim.keymap.set("n", "<leader>4", ":tabn 4<CR>")
vim.keymap.set("n", "<leader>5", ":tabn 5<CR>")
