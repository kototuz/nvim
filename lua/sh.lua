local build_win_map = {}

function current_build_win()
    local tabpage = vim.api.nvim_get_current_tabpage()
    if build_win_map[tabpage] == nil then
        build_win_map[tabpage] = {}
    end

    return build_win_map[tabpage]
end

local function run_shell_command(cmd)
    local build_win = current_build_win()

    -- Delete old buffer
    local no_window = (not build_win.buf) or vim.fn.bufwinid(build_win.buf) == -1
    if build_win.buf == not nil and vim.api.nvim_buf_is_valid(build_win.buf) then
        vim.api.nvim_buf_delete(build_win.buf, { force = true })
    end

    -- Create new buffer
    build_win.buf = vim.api.nvim_create_buf(false, true)

    -- Open window if it is not opened
    if no_window then
        build_win.win = vim.api.nvim_open_win(build_win.buf, false, {
            split = 'below',
            win = 0,
        })
    else
        vim.api.nvim_win_set_buf(build_win.win, build_win.buf)
    end

    -- Run command
    vim.api.nvim_win_call(build_win.win, function()
        vim.fn.jobstart(cmd, { term = true })
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
    local build_win = current_build_win()

    -- Get input from user if the run register is empty
    if build_win.last_cmd == nil then
        vim.ui.input({ prompt = "sh: ", completion=("customlist,%s"):format("CompileInputComplete") }, function(new_cmd)
            if new_cmd == nil or new_cmd == "" then return end
            build_win.last_cmd = new_cmd
            run_shell_command(new_cmd)
        end)
    else
        run_shell_command(build_win.last_cmd)
    end
end)

-- The keymap takes command from the user and
-- puts the command into 'run' register
vim.keymap.set("n", "<leader>;", function()
    vim.ui.input({ prompt = "sh: ", default = "", completion=("customlist,%s"):format("CompileInputComplete") }, function(new_cmd)
        if new_cmd == nil or new_cmd == "" then return end
        current_build_win().last_cmd = new_cmd
        run_shell_command(new_cmd)
    end)
end)

-- Scroll the build window up
vim.keymap.set("n", "<C-k>", function()
    local build_win = current_build_win()
    local no_window = (not build_win.buf) or vim.fn.bufwinid(build_win.buf) == -1
    if not no_window then
        vim.api.nvim_win_call(build_win.win, function()
            vim.cmd("exe \"normal! \\<C-u>\"")
        end)
    end
end)

-- Scroll the build window down
vim.keymap.set("n", "<C-j>", function()
    local build_win = current_build_win()
    local no_window = (not build_win.buf) or vim.fn.bufwinid(build_win.buf) == -1
    if not no_window then
        vim.api.nvim_win_call(build_win.win, function()
            vim.cmd("exe \"normal! \\<C-d>\"")
        end)
    end
end)
