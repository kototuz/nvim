--
-- local group = vim.api.nvim_create_augroup("custom-term-open", {})
-- vim.api.nvim_create_autocmd("TermOpen", {
--     group = group,
--     callback = function()
    --     local set = vim.opt_local
--         set.number = false
--         set.relativenumber = false
--         set.scrolloff = 0
--         vim.bo.bufhidden = "delete"
--         vim.bo.filetype = "terminal"
--         vim.cmd.normal("i")
--     end,
-- })

vim.keymap.set("t", "<c-c><c-c>", "<c-\\><c-n>")
vim.keymap.set("n", "<leader>t", function()
    vim.cmd.terminal()
    vim.cmd.normal("i")
    local set = vim.opt_local
    set.number = false
    set.relativenumber = false
    set.scrolloff = 0
    vim.bo.bufhidden = "delete"
    vim.bo.filetype = "terminal"
end)
