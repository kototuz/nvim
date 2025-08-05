vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("custom-term-open", {}),
    callback = function()
        local set = vim.opt_local
        set.number = false
        set.relativenumber = false
        set.scrolloff = 0
        vim.bo.bufhidden = "delete"
        vim.bo.filetype = "terminal"
    end,
})

vim.keymap.set("t", "<C-c>", "<c-\\><c-n>")
vim.keymap.set("n", "<leader>t", function()
    vim.cmd.terminal()
    vim.cmd.normal("i")
end)
