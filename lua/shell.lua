local shell = {
    output_bufnr = -1,
    output_winid = -1,
}

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

function shell.setup(opts)
    opts = opts or {}
    opts.keymaps = opts.keymaps or {}

    vim.keymap.set("n", opts.keymaps.input or "<leader>;", shell.input)
    vim.keymap.set("n", opts.keymaps.run_last or "<leader>l", shell.run_last_or_input)
    vim.keymap.set("n", opts.keymaps.scroll_output_up or "<C-k>", shell.scroll_output_up)
    vim.keymap.set("n", opts.keymaps.scroll_output_down or "<C-j>", shell.scroll_output_down)

    vim.keymap.set("n", opts.keymaps.telescope or "<leader>h", shell.search_history)

    shell.history_len = opts.history_len or 100

    shell.telescope_opts = opts.telescope_opts

    shell.chan_id = vim.fn.jobstart({ vim.fn.stdpath("config") .. "/shell.sh" }, {
        pty = true,
        on_stdout = function(_, data)
            if shell.output_chan_id then
                vim.fn.chansend(shell.output_chan_id, data)
            end
        end,
        on_stderr = function(_, data)
            if shell.output_chan_id then
                vim.fn.chansend(shell.output_chan_id, data)
            end
        end,
    })
end

function shell.open_output_win()
    local tabpage_wins = vim.api.nvim_tabpage_list_wins(0)
    if vim.fn.index(tabpage_wins, shell.output_winid) ~= -1 then
        vim.api.nvim_win_set_buf(shell.output_winid, shell.output_bufnr)
    else
        if vim.api.nvim_win_is_valid(shell.output_winid) then
            vim.api.nvim_win_close(shell.output_winid, false)
        end
        shell.output_winid = vim.api.nvim_open_win(shell.output_bufnr, false, {
            split = 'below',
            win = 0,
        })
    end
end

function shell.run(cmd, cwd)
    if not vim.api.nvim_buf_is_loaded(shell.output_bufnr) then
        shell.output_bufnr = vim.api.nvim_create_buf(false, true)
    end

    shell.open_output_win()

    -- Run command
    vim.api.nvim_set_option_value("modifiable", true, { buf = shell.output_bufnr })
    vim.api.nvim_buf_set_lines(shell.output_bufnr, 0, -1, false, {})
    shell.output_chan_id = vim.api.nvim_open_term(shell.output_bufnr, {
        on_input = function(_, _, _, data)
            if data == "" or data == "" then
                vim.api.nvim_chan_send(shell.chan_id, data)
            end
        end
    })

    vim.api.nvim_chan_send(shell.chan_id, (cwd or vim.fn.getcwd()) .. "\n" .. cmd .. "\n")
    vim.api.nvim_buf_call(shell.output_bufnr, function()
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

function shell.run_last_or_input(cwd)
    if shell.last_cmd == nil then
        shell.input({ cwd = cwd })
    else
        shell.run(shell.last_cmd, cwd)
    end
end

function shell.history()
    local history = vim.api.nvim_cmd({ cmd = "history", args = {"input"} }, { output = true })
    history = vim.fn.split(history, '\n')

    local prefix_end = 4
    local last_entry = history[#history]
    while last_entry:sub(prefix_end, prefix_end) ~= ' ' do prefix_end = prefix_end + 1 end
    prefix_end = prefix_end + 2

    for i, entry in ipairs(history) do
        history[i] = entry:sub(prefix_end)
    end

    return vim.fn.slice(vim.fn.reverse(history), 0, shell.history_len)
end

function shell.input(opts)
    opts = opts or {}
    vim.ui.input({ prompt = "sh: ", default = opts.default or "", completion=("customlist,%s"):format("CompileInputComplete") }, function(new_cmd)
        if new_cmd == nil or new_cmd == "" then return end
        if opts.cmd_suffix then
            new_cmd = new_cmd .. opts.cmd_suffix
        end

        shell.last_cmd = new_cmd
        shell.run(new_cmd, opts.cwd)
    end)
end

function shell.scroll_output_up()
    if vim.api.nvim_buf_is_loaded(shell.output_bufnr) then
        shell.open_output_win()
        vim.api.nvim_win_call(shell.output_winid, function()
            vim.cmd("exe \"normal! \\<C-u>\"")
        end)
    end
end

function shell.scroll_output_down()
    if vim.api.nvim_buf_is_loaded(shell.output_bufnr) then
        shell.open_output_win()
        vim.api.nvim_win_call(shell.output_winid, function()
            vim.cmd("exe \"normal! \\<C-d>\"")
        end)
    end
end

function shell.search_history(cwd)
    local opts = shell.telescope_opts or {}
    pickers.new(opts, {
        prompt_title = "history",
        finder = finders.new_table { results = shell.history() },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(promp_bufnr, map)
            actions.select_default:replace(function()
                actions.close(promp_bufnr)
                local selection = action_state.get_selected_entry()[1]
                shell.input({ default = selection, cwd = cwd })
            end)

            return true
        end
    }):find()
end

return shell
