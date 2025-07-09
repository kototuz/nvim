-- FILE EXPLORER - FE

-- ========================================
-- FE API
-- ========================================

local Fe = { on_open_actions = {} }

function Fe:render(mark)
    self.files = {}
    for filename, type in vim.fs.dir(self.dir) do
        self.files = vim.fn.add(self.files, {
            name = filename,
            type = type
        })
    end

    if not self.show_hidden then
        self.files = vim.fn.filter(self.files, function(_, file)
            return file.name:sub(1, 1) ~= '.'
        end)
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
        if file.type == "directory" then
            return file.name .. "/"
        else
            return file.name
        end
    end)

    if mark ~= nil then
        for i = mark.file_range.b, mark.file_range.e do
            filenames[i] = mark.symbol .. filenames[i]
        end
    end

    vim.api.nvim_set_option_value("modifiable", true, { buf = self.buf })
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, filenames)
    vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })
end

function Fe:keymap(modes, binding, action)
    table.insert(self.on_open_actions, function(buf)
        vim.keymap.set(modes, binding, action, { buffer = buf })
    end)
end

function Fe:autocmd(event, callback)
    table.insert(self.on_open_actions, function(buf)
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
    Fe:render()
end

function Fe:delete(file_range)
    vim.ui.input({ prompt = "Delete? " }, function(input)
        if input ~= "y" then return end
        for i = file_range.b, file_range.e do
            local file = self.files[i]
            if file == nil then return end
            vim.fs.rm(Fe:path_with(file.name), { recursive = true })
        end
        Fe:render()
    end)
end

function Fe:mark(file_range, as_copy)
    self.marks = { copy = as_copy, file_paths = {} }
    for i = file_range.b, file_range.e do
        local file = self.files[i]
        if file == nil then return end
        table.insert(self.marks.file_paths, Fe:path_with(file.name))
    end
end

function Fe:paste()
    local command
    if self.marks.copy then
        command = function(src, dst)
            vim.fn.system { "cp", "-r", src, dst }
        end
    else
        command = function(src, dst)
            vim.fn.system { "mv", src, dst }
        end
    end

    for _, file_path in pairs(self.marks.file_paths) do
        command(file_path, self.dir)
    end

    Fe:render()
end

function Fe:create()
    vim.ui.input({ prompt = "Create: " }, function(input)
        if input == nil or input == "" then return end

        if input:sub(-1) == '/' then
            vim.fn.mkdir(Fe:path_with(input), "p")
        else
            local new_file = io.open(Fe:path_with(input), "w")
            new_file:close()
        end

        Fe:render()
    end)
end

function Fe:rename(file_idx)
    local file = self.files[file_idx]
    if file == nil then return end
    vim.ui.input({ prompt = "Rename: ", default = file.name }, function(input)
        if input == nil or input == "" then return end
        vim.fn.rename(Fe:path_with(file.name), Fe:path_with(input))
        Fe:render()
    end)
end

function Fe:cd_back()
    Fe:set_dir(vim.fs.dirname(self.dir))
end

function Fe:cd(file_idx)
    local file = self.files[file_idx]
    if file == nil then return end

    local new_path = Fe:path_with(file.name)
    if file.type ~= "directory" then
        vim.cmd.edit(new_path)
        return
    end

    Fe:set_dir(new_path)
end

function Fe:open(path)
    self.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("syntax", "netrw", { buf = self.buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })

    self.show_hidden = false
    for _, action in ipairs(self.on_open_actions) do
        action(self.buf)
    end

    Fe:set_dir(path)
    vim.api.nvim_win_set_buf(0, self.buf)
end

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

-- ========================================
-- SETUP
-- ========================================

Fe:keymap("n", "h",     function() Fe:cd_back() end)
Fe:keymap("n", "c",     function() Fe:create() end)
Fe:keymap("n", "p",     function() Fe:paste() end)
Fe:keymap("n", "i",     function() vim.fn.chdir(Fe.dir) end)
Fe:keymap("n", "<C-l>", function() Fe:render() end)
Fe:keymap("n", "l",     function() Fe:cd(cursor_row()) end)
Fe:keymap("n", "r",     function() Fe:rename(cursor_row()) end)

Fe:keymap("n", ".", function()
    Fe.show_hidden = not Fe.show_hidden
    Fe:render()
end)

Fe:keymap({ "n", "v" }, "d", function() 
    Fe:delete(selection_range())
    vim.api.nvim_input("<Esc>")
end)

Fe:keymap({ "n", "v" }, "m", function() 
    Fe:mark(selection_range(), false)
    vim.api.nvim_input("<Esc>")
end)

Fe:autocmd("TextYankPost", function()
    local event = vim.api.nvim_get_vvar("event")
    if event.operator ~= 'y' then return end
    Fe:mark(range(vim.fn.getpos("'[")[2], vim.fn.getpos("']")[2]), true)
end)

vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("Fe", { clear = true }),
    callback = function()
        local buf = vim.api.nvim_win_get_buf(0)
        local path = vim.api.nvim_buf_get_name(buf)
        local stat = vim.uv.fs_stat(path)
        if stat ~= nil and stat.type == "directory" then
            vim.api.nvim_buf_delete(buf, { force = true })
            Fe:open(path)
        end
    end
})
