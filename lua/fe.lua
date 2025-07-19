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

-- Define file explorer type
local Fe = {}
Fe.__index = Fe

local global = {
    on_open_actions = {},
    marks = { copy = nil, file_paths = {} },
    instance_map = {}
}

function Fe.new()
    local self = setmetatable({}, Fe)
    self.buf          = nil
    self.prev_buf     = nil
    self.dir          = nil
    self.files        = nil
    self.verbose_mode = false
    return self
end

function Fe:render(mark)
    self.files = {}
    for filename, type in vim.fs.dir(self.dir) do
        self.files = vim.fn.add(self.files, {
            name = filename,
            type = type
        })
    end

    local render_file_fn
    if not self.verbose_mode then
        self.files = vim.fn.filter(self.files, function(_, file)
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
            local file_size = vim.fn.getfsize(self:path_with(file.name))
            local res = format_size(file_size) .. " " .. file.name
            if file.type == "directory" then
                res = res .. "/"
            end
            return res
        end
    end

    self.files = vim.fn.sort(self.files, function(lhs, rhs)
        if lhs.type == "directory" and rhs.type ~= "directory" then
            return -1
        end
        if lhs.type ~= "directory" and rhs.type == "directory" then
            return 1
        end
        return 0
    end)

    local filenames = vim.fn.map(self.files, function(_, file)
        return render_file_fn(file)
    end)

    if mark ~= nil then
        for i = mark.file_range.b, mark.file_range.e do
            filenames[i] = mark.symbol .. filenames[i]
        end
    end

    vim.api.nvim_buf_set_name(self.buf, string.format("fe%d:%s", self.buf, self.dir))
    vim.api.nvim_set_option_value("modifiable", true, { buf = self.buf })
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, filenames)
    vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })
end

function global.keymap(modes, binding, action)
    table.insert(global.on_open_actions, function(buf)
        vim.keymap.set(modes, binding, function()
            action(global.instance_map[buf])
        end, { buffer = buf })
    end)
end

function global.autocmd(event, callback)
    table.insert(global.on_open_actions, function(buf)
        vim.api.nvim_create_autocmd(event, {
            buffer = buf,
            callback = callback
        })
    end)
end

function Fe:path_with(path)
    return vim.fs.joinpath(self.dir, path)
end

function Fe:set_dir(path)
    self.dir = path
    self:render()
end

function Fe:delete(file_range)
    if #self.files == 0 then return end
    vim.ui.input({ prompt = "Delete? " }, function(input)
        if input ~= "y" then return end
        for i = file_range.b, file_range.e do
            local file = self.files[i]
            assert(file)
            vim.fs.rm(self:path_with(file.name), { recursive = true })
        end
        self:render()
    end)
end

function Fe:mark(file_range, as_copy)
    if #self.files == 0 then return end
    global.marks = { copy = as_copy, file_paths = {} }
    for i = file_range.b, file_range.e do
        local file = self.files[i]
        assert(file)
        table.insert(global.marks.file_paths, self:path_with(file.name))
    end
end

function Fe:paste()
    if global.marks == nil then return end

    local command
    if global.marks.copy then
        command = function(src, dst)
            vim.fn.system { "cp", "-r", src, dst }
        end
    else
        command = function(src, dst)
            vim.fn.system { "mv", src, dst }
        end
    end

    for _, file_path in pairs(global.marks.file_paths) do
        command(file_path, self.dir)
    end
    global.marks = nil

    self:render()
end

function Fe:create()
    vim.ui.input({ prompt = "Create: " }, function(input)
        if input == nil or input == "" then return end

        if input:sub(-1) == '/' then
            vim.fn.mkdir(self:path_with(input), "p")
        else
            local new_file = io.open(self:path_with(input), "w")
            new_file:close()
        end

        self:render()
    end)
end

function Fe:rename(file_idx)
    if #self.files == 0 then return end
    local file = self.files[file_idx]
    assert(file)
    vim.ui.input({ prompt = "Rename: ", default = file.name }, function(input)
        if input == nil or input == "" then return end
        vim.fn.rename(self:path_with(file.name), self:path_with(input))
        self:render()
    end)
end

function Fe:cd_back()
    self:set_dir(vim.fs.dirname(self.dir))
end

function Fe:cd(file_idx)
    if #self.files == 0 then return end
    local file = self.files[file_idx]
    assert(file)

    local new_path = self:path_with(file.name)
    if file.type ~= "directory" then
        vim.cmd.edit(new_path)
        return
    end

    self:set_dir(new_path)
end

function Fe.open(path)
    if vim.uv.fs_stat(path) == nil then
        print("Path does not exist")
        return
    end

    local new_fe = Fe.new()

    new_fe.prev_buf = vim.api.nvim_win_get_buf(0)

    new_fe.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("modifiable", false, { buf = new_fe.buf })
    vim.api.nvim_set_option_value("buftype", "nowrite", { buf = new_fe.buf })
    vim.api.nvim_set_option_value("bufhidden", "delete", { buf = new_fe.buf })

    for _, action in ipairs(global.on_open_actions) do
        action(new_fe.buf)
    end

    new_fe:set_dir(path)
    vim.api.nvim_win_set_buf(0, new_fe.buf)

    global.instance_map[new_fe.buf] = new_fe

    vim.cmd "syntax match dir '.\\+/'"
    vim.cmd "hi def link dir Directory"
end

function Fe:close()
    vim.api.nvim_win_set_buf(0, self.prev_buf)
    vim.api.nvim_buf_delete(self.buf, { force = true })
end

-- ========================================
-- USE FE TO OPEN DIRECTORIES
-- ========================================

-- Delete netrw stuff
vim.api.nvim_del_augroup_by_name("FileExplorer");

local group = vim.api.nvim_create_augroup("Fe", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
        local buf = vim.api.nvim_win_get_buf(0)
        local path = vim.api.nvim_buf_get_name(buf)
        local stat = vim.uv.fs_stat(path)
        if stat ~= nil and stat.type == "directory" then
            vim.api.nvim_buf_delete(buf, { force = true })
            Fe.open(path)
        end
    end
})

vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
        local is_valid = vim.api.nvim_buf_is_valid(2)
        if is_valid then
            vim.api.nvim_buf_delete(2, { force = true })
        end
    end
})

-- ========================================
-- KEYMAPS INSIDE FE
-- ========================================

global.keymap("n", "h",     function(fe) fe:cd_back() end)
global.keymap("n", "a",     function(fe) fe:create() end)
global.keymap("n", "p",     function(fe) fe:paste() end)
global.keymap("n", "i",     function(fe) vim.fn.chdir(fe.dir) end)
global.keymap("n", "<C-l>", function(fe) fe:render() end)
global.keymap("n", "l",     function(fe) fe:cd(cursor_row()) end)
global.keymap("n", "r",     function(fe) fe:rename(cursor_row()) end)
global.keymap("n", "q",     function(fe) fe:close() end)
global.keymap("n", ";",     function(fe) fe:set_dir(vim.fn.getcwd()) end)

global.keymap("n", ".", function(fe)
    fe.verbose_mode = not fe.verbose_mode
    fe:render()
end)

global.keymap({ "n", "v" }, "d", function(fe) 
    fe:delete(selection_range())
    vim.api.nvim_input("<Esc>")
end)

global.keymap({ "n", "v" }, "m", function(fe)
    fe:mark(selection_range(), false)
    vim.api.nvim_input("<Esc>")
end)

global.autocmd("TextYankPost", function()
    local event = vim.api.nvim_get_vvar("event")
    if event.operator ~= 'y' then return end

    local curr_buf = vim.api.nvim_win_get_buf(0)
    local fe = global.instance_map[curr_buf]
    fe:mark(range(vim.fn.getpos("'[")[2], vim.fn.getpos("']")[2]), true)
end)

-- ========================================
-- KEYMAPS OUTSIDE FE
-- ========================================

vim.keymap.set("n", "<leader>p", function()
    local curr_buf = vim.api.nvim_get_current_buf()

    local dir
    local fe = global.instance_map[curr_buf]
    if fe then
        dir = fe.dir
    else
        dir = vim.fs.dirname(vim.api.nvim_buf_get_name(curr_buf))
    end

    Fe.open(dir)
end)
