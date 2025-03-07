local build_buffer = nil
local build_win = nil

local function run_shell_command(cmd)
    -- Delete old buffer
    local no_window = (not build_buffer) or vim.fn.bufwinid(build_buffer) == -1
    if build_buffer == not nil and vim.api.nvim_buf_is_valid(build_buffer) then
        vim.api.nvim_buf_delete(build_buffer, { force = true })
    end

    -- Create new buffer
    build_buffer = vim.api.nvim_create_buf(false, true)

    -- Open window if it is not opened
    if no_window then
        build_win = vim.api.nvim_open_win(build_buffer, false, {
            split = 'below',
            win = 0,
        })
    else
        vim.api.nvim_win_set_buf(build_win, build_buffer)
    end
-- Run command
    vim.api.nvim_win_call(build_win, function()
        vim.fn.termopen(cmd, { on_stdout = function()end, on_stderr = function()end })
        vim.cmd("normal G")
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
    local cmd = vim.api.nvim_exec2("echo @r", { output = true }).output
    if cmd == "" then
        vim.ui.input({ prompt = "sh: ", completion=("customlist,%s"):format("CompileInputComplete") }, function(new_cmd)
            if new_cmd == nil then return end
            cmd = new_cmd
            vim.fn.setreg("r", cmd)
        end)
        if cmd == "" then return end
    end
    run_shell_command(cmd)
end)

-- The keymap takes command from the user and
-- puts the command into 'run' register
vim.keymap.set("n", "<leader>;", function()
    vim.ui.input({ prompt = "sh: ", default = "", completion=("customlist,%s"):format("CompileInputComplete") }, function(new_cmd)
        if new_cmd == nil then return end
        vim.fn.setreg("r", new_cmd)
        run_shell_command(new_cmd)
    end)
end)

-- Scroll the build window up
vim.keymap.set("n", "<C-k>", function()
    local no_window = (not build_buffer) or vim.fn.bufwinid(build_buffer) == -1
    if not no_window then
        vim.api.nvim_win_call(build_win, function()
            vim.cmd("exe \"normal! \\<C-u>\"")
        end)
    end
end)

-- Scroll the build window down
vim.keymap.set("n", "<C-j>", function()
    local no_window = (not build_buffer) or vim.fn.bufwinid(build_buffer) == -1
    if not no_window then
        vim.api.nvim_win_call(build_win, function()
            vim.cmd("exe \"normal! \\<C-d>\"")
        end)
    end
end)
