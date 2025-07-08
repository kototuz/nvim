-- FILE EXPLORER - FE

local Fe = {}

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

function range(b, e)
    if b > e then b, e = e, b end
    return { b = b, e = e }
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

function Fe:mark(file_range, as_copy, mark_symbol)
    self.marks = { copy = as_copy, file_paths = {} }
    for i = file_range.b, file_range.e do
        local file = self.files[i]
        if file == nil then return end
        table.insert(self.marks.file_paths, Fe:path_with(file.name))
    end

    local mark = {
        file_range = file_range,
        symbol = mark_symbol
    }

    Fe:render(mark)
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

function Fe:open(buf, path)
    self.buf = buf
    self.show_hidden = false
    Fe:set_dir(path)
    vim.api.nvim_set_option_value("syntax", "netrw", { buf = buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    vim.api.nvim_win_set_buf(0, self.buf)
end

vim.api.nvim_create_user_command("Fe", function()
    local buf = vim.api.nvim_create_buf(false, true)

    vim.keymap.set("n", "h", function() Fe:cd_back() end, { buffer = buf })

    vim.keymap.set("n", "l", function() 
        local c = vim.api.nvim_win_get_cursor(0)
        Fe:cd(c[1])
    end, { buffer = buf})

    vim.keymap.set("n", ".", function()
        Fe.show_hidden = not Fe.show_hidden
        Fe:render()
    end, { buffer = buf })

    vim.keymap.set({ "n", "v" }, "d", function() 
        Fe:delete(range(vim.fn.getpos("v")[2], vim.fn.getpos(".")[2]))
        vim.api.nvim_input("<Esc>")
    end, { buffer = buf})

    vim.keymap.set("n", "a", function()
        Fe:create()
    end, { buffer = buf })

    vim.keymap.set("n", "r", function()
        local c = vim.api.nvim_win_get_cursor(0)
        Fe:rename(c[1])
    end, { buffer = buf })

    vim.keymap.set({ "n", "v" }, "c", function() 
        Fe:mark(
            range(vim.fn.getpos("v")[2], vim.fn.getpos(".")[2]),
            true, "*"
        )
        vim.api.nvim_input("<Esc>")
    end, { buffer = buf})

    vim.keymap.set({ "n", "v" }, "m", function() 
        Fe:mark(
            range(vim.fn.getpos("v")[2], vim.fn.getpos(".")[2]),
            false, "*"
        )
        vim.api.nvim_input("<Esc>")
    end, { buffer = buf})

    vim.keymap.set("n", "p", function()
        Fe:paste()
    end, { buffer = buf })

    vim.keymap.set("n", "i", function()
        vim.fn.chdir(Fe.dir)
    end, { buffer = buf })

    vim.keymap.set("n", "<C-l>", function()
        Fe:render()
    end, { buffer = buf })

    Fe:open(buf, vim.fn.getcwd())
end, {})
