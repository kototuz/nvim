local buf = -1
local win = -1
local last_cmd = nil

-- SETUP SHELL --------------------------------------------
local term_chan_id = nil
local shell_chan_id = vim.fn.jobstart({ "bash" }, {
    pty = true,
    on_stdout = function(_, data)
        if term_chan_id then
            vim.fn.chansend(term_chan_id, data)
        end
    end,
    on_stdout = function(_, data)
        if term_chan_id then
            vim.fn.chansend(term_chan_id, data)
        end
    end,
})

vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("Sh", { clear = true }),
    callback = function()
        term_chan_id = nil
        local event = vim.api.nvim_get_vvar("event")
        vim.api.nvim_chan_send(shell_chan_id, "cd " .. event.cwd .. "\n")
    end
})

vim.api.nvim_chan_send(shell_chan_id, "PROMPT_COMMAND=\"PS1=\\\"\n[Process exited \\$?]\\\"\";")
-----------------------------------------------------------

function is_win_opened()
    if not vim.api.nvim_win_is_valid(win) then return false end
    local tabpage_wins = vim.api.nvim_tabpage_list_wins(0)
    return vim.fn.index(tabpage_wins, win) ~= -1
end

function open_win()
    local tabpage_wins = vim.api.nvim_tabpage_list_wins(0)
    if vim.fn.index(tabpage_wins, win) ~= -1 then
        vim.api.nvim_win_set_buf(win, buf)
    else
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, false)
        end
        win = vim.api.nvim_open_win(buf, false, {
            split = 'below',
            win = 0,
        })
    end
end

function run_shell_command(cmd)
    if not vim.api.nvim_buf_is_loaded(buf) then
        buf = vim.api.nvim_create_buf(false, true)
    end

    open_win()

    -- Run command
    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    term_chan_id = vim.api.nvim_open_term(buf, {
        on_input = function(_, _, _, data)
            vim.api.nvim_chan_send(shell_chan_id, data)
        end
    })

    vim.api.nvim_chan_send(shell_chan_id, cmd .. "\n")
    vim.api.nvim_buf_call(buf, function()
        vim.cmd.normal("G")
    end)
end

-- Completion function
vim.cmd([[
function! CompileInputComplete(ArgLead, CmdLine, CursorPos)
    let HasNoSpaces = a:CmdLine =~ '^\S\+$'
    let Results = getcompletion('!' . a:CmdLine, 'cmdline')
    let TransformedResults = map(Results, 'HasNoSpaces ? v:val : a:CmdLine[:strridx(a:CmdLine, " ") - 1] . " " . v:val')
    return TransformedResults
endfunction
]])

-- The keymap run last command
-- If the 'run' register is empty we take it from the user
vim.keymap.set("n", "<leader>l", function()
    -- Get input from user if the run register is empty
    if last_cmd == nil then
        vim.ui.input({ prompt = "sh: ", completion=("customlist,%s"):format("CompileInputComplete") }, function(new_cmd)
            if new_cmd == nil or new_cmd == "" then return end
            last_cmd = new_cmd
            run_shell_command(new_cmd)
        end)
    else
        run_shell_command(last_cmd)
    end
end)

-- The keymap takes command from the user and
-- puts the command into 'run' register
vim.keymap.set("n", "<leader>;", function()
    vim.ui.input({ prompt = "sh: ", default = "", completion=("customlist,%s"):format("CompileInputComplete") }, function(new_cmd)
        if new_cmd == nil or new_cmd == "" then return end
        last_cmd = new_cmd
        run_shell_command(new_cmd)
    end)
end)

-- Scroll the build window up
vim.keymap.set("n", "<C-k>", function()
    if vim.api.nvim_buf_is_loaded(buf) then
        open_win()
        vim.api.nvim_win_call(win, function()
            vim.cmd("exe \"normal! \\<C-u>\"")
        end)
    end
end)

-- Scroll the build window down
vim.keymap.set("n", "<C-j>", function()
    if vim.api.nvim_buf_is_loaded(buf) then
        open_win()
        vim.api.nvim_win_call(win, function()
            vim.cmd("exe \"normal! \\<C-d>\"")
        end)
    end
end)
