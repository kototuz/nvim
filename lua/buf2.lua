local tab_letter = { 'a', 's', 'd', 'f', 'g' }

for i, tab in ipairs(tab_letter) do
    vim.keymap.set("n", "'"..tab, function() vim.cmd.tabnext(i) end)
    vim.keymap.set({ "n", "i" }, "<C-"..i..">", function() vim.cmd.tabnext(i) end)
end

vim.opt.tabline = "%!v:lua.PillTabline()"
function _G.PillTabline()
    local s = ""
    local tabs = vim.api.nvim_list_tabpages()
    local current = vim.api.nvim_get_current_tabpage()

    for i, tab in ipairs(tabs) do
        local is_active = (tab == current)
        local hl = is_active and "%#TabLine#" or "%#TabLineFill#"
        s = s .. hl .. " " .. tab_letter[i] .. " " .. "%#TabLineFill#"
    end

    return s
end
