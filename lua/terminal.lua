-- vim.api.nvim_create_autocmd("TermOpen", {
--     group = vim.api.nvim_create_augroup("custom-term-open", {}),
--     callback = function()
--         local set = vim.opt_local
--         set.number = false
--         set.relativenumber = false
--         set.scrolloff = 0
--         vim.bo.bufhidden = "delete"
--         vim.bo.filetype = "terminal"
--     end,
-- })

vim.keymap.set("t", "<C-x>", "<C-c>")
vim.keymap.set("t", "<C-c>", "<c-\\><c-n>")

-- local buf = -1
-- local chan = nil
-- vim.keymap.set("n", "<leader>t", function()
--     if not vim.api.nvim_buf_is_valid(buf) then
--         buf = vim.api.nvim_create_buf(false, true)
--         vim.api.nvim_buf_call(buf, vim.cmd.terminal)
--         vim.api.nvim_set_option_value("buflisted", false, { buf = buf })
--         chan = vim.bo[buf].channel
--     end
--
--     vim.api.nvim_chan_send(chan, "cd " .. vim.fn.getcwd() .. "\nclear\n")
--
--     local win = vim.fn.bufwinid(buf)
--     if not vim.api.nvim_win_is_valid(win) then
--         win = vim.api.nvim_open_win(buf, true, {
--             split = 'below',
--             win = 0,
--         })
--
--         vim.cmd.normal("i")
--     end
-- end)
