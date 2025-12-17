-- FILE EXPLORER - FE

-- ========================================
-- UTILS
-- ========================================

function range(b, e)
    if b > e then b, e = e, b end
    return { b = b, e = e }
end

function selection_range()
    return range(vim.fn.getpos("v")[2], vim.fn.getpos(".")[2])
end

function cursor_row()
    return vim.fn.getpos(".")[2]
end

function string:starts_with(start)
    return self:sub(1, start:len()) == start
end

-- ========================================
-- FE API
-- ========================================

local state = {
    buffers = {-1,-1,-1},
    augroup = vim.api.nvim_create_augroup("Fe", { clear = true }),
    edit_win = -1,
}

function setup_buf(buf)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_set_option_value("filetype", "netrw", { buf = buf })

    function split() 
        vim.cmd.split()
        open(vim.b.fe_dir, 0)
    end
    function vsplit()
        vim.cmd.vsplit()
        open(vim.b.fe_dir, 0)
    end
    vim.keymap.set("n", "<C-w>v", vsplit, { buffer = buf })
    vim.keymap.set("n", "<C-w><C-v>", vsplit, { buffer = buf })
    vim.keymap.set("n", "<C-w>s", split, { buffer = buf })
    vim.keymap.set("n", "<C-w><C-s>", split, { buffer = buf })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = state.augroup,
        buffer = buf,
        callback = function()
            render()
        end
    })

    -- Close fe
    vim.keymap.set("n", "q", function()
        vim.api.nvim_win_set_buf(0, state.prev_buf)
    end, { buffer = buf })

    -- Cd or open file
    vim.keymap.set("n", "l", function()
        local filename = state.files[cursor_row()]
        if filename == nil then return end

        local norm_filename = get_norm_filename(cursor_row())
        local path = dir_path_with(norm_filename)
        if filename:sub(-1) == "/" then
            set_dir(path)
            vim.api.nvim_win_set_cursor(0, {1, 0})
        else
            local cwd = vim.fn.getcwd() .. "/"
            if path:starts_with(cwd) then
                path = path:sub(cwd:len()+1, -1)
            end

            if vim.api.nvim_win_is_valid(state.edit_win) then
                vim.api.nvim_set_current_win(state.edit_win)
            end
            vim.cmd.edit(path)
        end
    end, { buffer = buf })

    -- Cd back
    vim.keymap.set("n", "h", function()
        set_dir(vim.fs.dirname(vim.b.fe_dir))
        vim.api.nvim_win_set_cursor(0, {1, 0})
    end, { buffer = buf })

    -- Create file
    vim.keymap.set("n", "a", function()
        vim.ui.input({ prompt = "create: " }, function(input)
            if input == nil or input == "" then return end

            if input:sub(-1) == '/' then
                vim.fn.mkdir(dir_path_with(input), "p")
            else
                local new_file = io.open(dir_path_with(input), "w")
                new_file:close()
            end

            render()
        end)
    end, { buffer = buf })

    -- Rename file
    vim.keymap.set("n", "r", function()
        local filename = get_norm_filename(cursor_row())
        if filename == nil then return end
        vim.ui.input({ prompt = "rename: ", default = filename }, function(input)
            if input == nil or input == "" then return end
            vim.fn.rename(dir_path_with(filename), dir_path_with(input))
            render()
        end)
    end, { buffer = buf })

    -- Delete files
    vim.keymap.set({ "n", "v" }, "d", function()
        if #state.files == 0 then return end
        vim.ui.input({ prompt = "delete? " }, function(input)
            if input ~= "y" then return end
            local file_range = selection_range()
            for i = file_range.b, file_range.e do
                local filename = get_norm_filename(i)
                assert(filename)
                vim.fs.rm(dir_path_with(filename), { recursive = true })
            end
            render()
        end)

        vim.api.nvim_input("<Esc>")
    end, { buffer = buf })

    -- Mark files; the move mode
    vim.keymap.set({ "n", "v" }, "m", function()
        mark_files(selection_range(), false)
        vim.api.nvim_input("<Esc>")
    end, { buffer = buf })

    -- Mark files; the copy mode
    vim.api.nvim_create_autocmd("TextYankPost", {
        buffer = buf,
        callback = function()
            local event = vim.api.nvim_get_vvar("event")
            if event.operator ~= 'y' then return end
            mark_files(range(vim.fn.getpos("'[")[2], vim.fn.getpos("']")[2]), true)
        end
    })

    -- Paste files
    vim.keymap.set("n", "p", function()
        if state.marks == nil then return end

        local command
        if state.marks.copy then
            command = function(src, dst)
                vim.fn.system { "cp", "-r", src, dst }
            end
        else
            command = function(src, dst)
                vim.fn.system { "mv", src, dst }
            end
        end

        for _, file_path in pairs(state.marks.file_paths) do
            command(file_path, vim.b.fe_dir)
        end
        state.marks = nil

        render()
    end, { buffer = buf })

    -- Set CWD to current tab directory
    vim.keymap.set("n", "i", function()
        vim.fn.chdir(vim.b.fe_dir)
        render()
    end, { buffer = buf })

    -- Set current tab directory to CWD
    vim.keymap.set("n", ";", function()
        set_dir(vim.fn.getcwd())
    end, { buffer = buf })

    -- Toggle verbose mode
    vim.keymap.set("n", ".", function()
        state.verbose_mode = not state.verbose_mode
        render()
    end, { buffer = buf })

    -- Rerender
    vim.keymap.set("n", "<C-l>", function() render() end, { buffer = buf })
end

function get_avail_buf()
    for i, buf in ipairs(state.buffers) do
        if not vim.api.nvim_buf_is_loaded(buf) then
            buf = vim.api.nvim_create_buf(false, false)
            setup_buf(buf)
            state.buffers[i] = buf
            return buf
        elseif vim.fn.bufwinid(buf) == -1 then
            return buf
        end
    end

    error("Not enough buffers")
end

function open(path, win)
    local norm_path = vim.fs.normalize(vim.fs.abspath(path))
    if vim.uv.fs_stat(norm_path) == nil then
        print("Path does not exist")
        return
    end

    -- state.prev_buf = vim.api.nvim_get_current_buf()
    state.verbose_mode = false

    local buf = get_avail_buf()
    vim.b[buf].fe_dir = norm_path
    vim.api.nvim_win_set_buf(win, buf)
    vim.cmd.clearjumps()
    vim.opt_local.cursorline = true

    return result
end

function set_dir(path)
    vim.b.fe_dir = path
    render()
end

function render()
    local command = { "ls", "--group-directories-first", "-F", vim.b.fe_dir }
    if state.verbose_mode then
        table.insert(command, "-A")
    end

    local output = vim.system(command, { text = true }):wait()
    state.files = vim.fn.split(output.stdout, "\n")
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, state.files)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

function dir_path_with(path)
    return vim.fs.joinpath(vim.b.fe_dir, path)
end

function mark_files(file_range, as_copy)
    if #state.files == 0 then return end
    state.marks = { copy = as_copy, file_paths = {} }
    for i = file_range.b, file_range.e do
        local filename = get_norm_filename(i)
        assert(filename)
        table.insert(state.marks.file_paths, dir_path_with(filename))
    end
end

function get_norm_filename(idx)
    local filename = state.files[idx]
    if filename == nil then return nil end
    local last_char = filename:sub(-1)
    if last_char == "/" or last_char == "*" or last_char == "@" then
        return filename:sub(1, -2)
    end

    return filename
end


-- ========================================
-- USE FE TO OPEN DIRECTORIES
-- ========================================

-- Delete netrw stuff
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.api.nvim_del_augroup_by_name("FileExplorer");

vim.api.nvim_create_autocmd("BufEnter", {
    group = state.augroup,
    callback = function()
        local new_buf = vim.api.nvim_win_get_buf(0)
        local path = vim.api.nvim_buf_get_name(new_buf)
        local stat = vim.uv.fs_stat(path)
        if stat ~= nil and stat.type == "directory" then
            local prev_buf = vim.fn.bufnr("#")
            local fe_buf_idx = vim.fn.index(state.buffers, prev_buf)
            if prev_buf ~= -1 and fe_buf_idx ~= -1 then
                vim.api.nvim_set_current_buf(state.buffers[fe_buf_idx+1])
                local new_path = vim.fs.normalize(vim.fs.abspath(path))
                set_dir(new_path)
            else
                open(path, 0)
                render()
            end

            vim.api.nvim_buf_delete(new_buf, { force = true })
        end
    end
})

-- ========================================
-- KEYMAPS AND COMMANDS OUTSIDE FE
-- ========================================

vim.api.nvim_create_user_command("Fe", function(opts)
    if opts.fargs[1] == nil then
        open(vim.fn.getcwd())
    else
        open(opts.fargs[1])
    end
end, { nargs = "?", complete = "dir_in_path" })

-- Open fe
vim.keymap.set("n", "<leader>p", function()
    local curr_buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
    local curr_buf_dir = vim.fs.dirname(curr_buf_name)
    state.edit_win = vim.api.nvim_get_current_win()
    open(curr_buf_dir, vim.api.nvim_open_win(0, true, {
        split = "left",
        width = 40,
        win = 0
    }))
end)
