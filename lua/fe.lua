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

local KB = 1024
local MB = KB^2
local GB = KB^3
function format_size(size)
    local formats = {
        { size/GB, "G" },
        { size/MB, "M" },
        { size/KB, "K" },
    }

    for _, f in ipairs(formats) do
        if math.floor(f[1]) > 0 then
            return string.format("%.1f%s", f[1], f[2])
        end
    end

    return tostring(size) .. "B"
end

-- ========================================
-- FE API
-- ========================================

local state = {}

function open(path)
    local norm_path = vim.fs.normalize(vim.fs.abspath(path))
    local curr_buf = vim.api.nvim_get_current_buf()
    if curr_buf == state.buf then
        set_dir(norm_path)
        return
    end

    if vim.uv.fs_stat(norm_path) == nil then
        print("Path does not exist")
        return
    end

    -- Save buffer to jump to it when fe is closed
    state.prev_buf = vim.api.nvim_win_get_buf(0)

    -- Init tabs
    state.tabs = {}
    state.curr_tab_idx = 1

    state.verbose_mode = false

    -- Update window config
    local columns = vim.o.columns
    local lines = vim.o.lines - 3 -- exclude 2 bottom lines with mode, buffer name, etc.
    state.win_config.width = math.floor(columns * 0.8)
    state.win_config.height = math.floor(lines * 0.8)
    state.win_config.col = math.floor((columns - state.win_config.width) / 2)
    state.win_config.row = math.floor((lines - state.win_config.height) / 2)
    state.win_config.title = "Tab 1"

    local result = vim.api.nvim_open_win(state.buf, true, state.win_config)

    -- Set directory for current tab
    set_dir(norm_path)

    -- Set highligting for directories
    vim.cmd "syntax match dir '.\\+/'"
    vim.cmd "hi def link dir Directory"

    vim.opt_local.cursorline = true

    return result
end

function open_tab(idx)
    if state.tabs[idx] == nil then
        state.tabs[idx] = state.tabs[state.curr_tab_idx]
    end

    state.win_config.title = "Tab " .. idx
    vim.api.nvim_win_set_config(0, state.win_config)

    state.curr_tab_idx = idx
    render()
end

function update_tab_title()
end

function set_dir(path)
    state.tabs[state.curr_tab_idx] = path
    render()
end

function get_dir()
    return state.tabs[state.curr_tab_idx]
end

function render()
    state.files = {}
    for filename, type in vim.fs.dir(get_dir()) do
        state.files = vim.fn.add(state.files, {
            name = filename,
            type = type
        })
    end

    local render_file_fn
    if not state.verbose_mode then
        state.files = vim.fn.filter(state.files, function(_, file)
            return file.name:sub(1, 1) ~= '.'
        end)

        render_file_fn = function(file)
            if file.type == "directory" then
                return file.name .. "/"
            else
                return file.name
            end
        end
    else
        render_file_fn = function(file)
            local file_size = vim.fn.getfsize(dir_path_with(file.name))
            local res = format_size(file_size) .. " " .. file.name
            if file.type == "directory" then
                res = res .. "/"
            end
            return res
        end
    end

    state.files = vim.fn.sort(state.files, function(lhs, rhs)
        if lhs.type == "directory" and rhs.type ~= "directory" then
            return -1
        end
        if lhs.type ~= "directory" and rhs.type == "directory" then
            return 1
        end
        return 0
    end)

    local filenames = vim.fn.map(state.files, function(_, file)
        return render_file_fn(file)
    end)

    vim.api.nvim_set_option_value("modifiable", true, { buf = state.buf })
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, filenames)
    vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })
end

function dir_path_with(path)
    return vim.fs.joinpath(get_dir(), path)
end

function mark_files(file_range, as_copy)
    if #state.files == 0 then return end
    state.marks = { copy = as_copy, file_paths = {} }
    for i = file_range.b, file_range.e do
        local file = state.files[i]
        assert(file)
        table.insert(state.marks.file_paths, dir_path_with(file.name))
    end
end


-- NOTE: Maybe this stuff will be useful in the future
-- ========================================
-- USE FE TO OPEN DIRECTORIES
-- ========================================
-- Delete netrw stuff
-- vim.g.loaded_netrw = 1
-- vim.g.loaded_netrwPlugin = 1
-- vim.api.nvim_del_augroup_by_name("FileExplorer");
-- local group = vim.api.nvim_create_augroup("Fe", { clear = true })
-- vim.api.nvim_create_autocmd("BufEnter", {
--     group = group,
--     callback = function()
--         local buf = vim.api.nvim_win_get_buf(0)
--         local path = vim.api.nvim_buf_get_name(buf)
--         local stat = vim.uv.fs_stat(path)
--         if stat ~= nil and stat.type == "directory" then
--             vim.api.nvim_buf_delete(buf, { force = true })
--             open(path)
--         end
--     end
-- })


-- ========================================
-- SETUP BUFFER AND WINDOW CONFIG
-- ========================================

state.buf = vim.api.nvim_create_buf(false, false)
vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })
vim.api.nvim_set_option_value("buftype", "nofile", { buf = state.buf })

state.win_config = {
    relative = "editor",
    border = "rounded",
}

-- ========================================
-- KEYMAPS INSIDE FE
-- ========================================

-- Close fe
vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(0, false)
end, { buffer = state.buf })

-- Cd
vim.keymap.set("n", "l", function()
    if #state.files == 0 then return end
    local file = state.files[cursor_row()]
    assert(file)

    local new_path = dir_path_with(file.name)
    if file.type == "directory" then
        set_dir(new_path)
    else
        vim.api.nvim_win_close(0, true)
        new_path = new_path:gsub(vim.fn.getcwd() .. "/", "")
        vim.cmd.edit(new_path)
    end
end, { buffer = state.buf })

-- Cd back
vim.keymap.set("n", "h", function()
    set_dir(vim.fs.dirname(get_dir()))
end, { buffer = state.buf })

-- Create file
vim.keymap.set("n", "a", function()
    vim.ui.input({ prompt = "Create: " }, function(input)
        if input == nil or input == "" then return end

        if input:sub(-1) == '/' then
            vim.fn.mkdir(dir_path_with(input), "p")
        else
            local new_file = io.open(dir_path_with(input), "w")
            new_file:close()
        end

        render()
    end)
end, { buffer = state.buf })

-- Rename file
vim.keymap.set("n", "r", function()
    if #state.files == 0 then return end
    local file = state.files[cursor_row()]
    assert(file)
    vim.ui.input({ prompt = "Rename: ", default = file.name }, function(input)
        if input == nil or input == "" then return end
        vim.fn.rename(dir_path_with(file.name), dir_path_with(input))
        render()
    end)
end, { buffer = state.buf })

-- Delete files
vim.keymap.set({ "n", "v" }, "d", function()
    if #state.files == 0 then return end
    vim.ui.input({ prompt = "Delete? " }, function(input)
        if input ~= "y" then return end
        local file_range = selection_range()
        for i = file_range.b, file_range.e do
            local file = state.files[i]
            assert(file)
            vim.fs.rm(dir_path_with(file.name), { recursive = true })
        end
        render()
    end)

    vim.api.nvim_input("<Esc>")
end, { buffer = state.buf })

-- Mark files; the move mode
vim.keymap.set({ "n", "v" }, "m", function()
    mark_files(selection_range(), false)
    vim.api.nvim_input("<Esc>")
end, { buffer = state.buf })

-- Mark files; the copy mode
vim.api.nvim_create_autocmd("TextYankPost", {
    buffer = state.buf,
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
        command(file_path, get_dir())
    end
    state.marks = nil

    render()
end, { buffer = state.buf })

-- Set CWD to current tab directory
vim.keymap.set("n", "i", function()
    vim.fn.chdir(get_dir())
    render()
end, { buffer = state.buf })

-- Set current tab directory to CWD
vim.keymap.set("n", ";", function()
    set_dir(vim.fn.getcwd())
end, { buffer = state.buf })

-- Toggle verbose mode
vim.keymap.set("n", ".", function()
    state.verbose_mode = not state.verbose_mode
    render()
end, { buffer = state.buf })

-- Rerender
vim.keymap.set("n", "<C-l>", function() render() end, { buffer = state.buf })

-- Open tab
vim.keymap.set("n", "o1", function() open_tab(1) end, { buffer = state.buf })
vim.keymap.set("n", "o2", function() open_tab(2) end, { buffer = state.buf })
vim.keymap.set("n", "o3", function() open_tab(3) end, { buffer = state.buf })
vim.keymap.set("n", "o4", function() open_tab(4) end, { buffer = state.buf })
vim.keymap.set("n", "o5", function() open_tab(5) end, { buffer = state.buf })

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
    open(curr_buf_dir)
end)

-- TODO: Use 'ls' command to render directory
