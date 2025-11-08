local curr_slot = 1
local slots = {
    { l = 'a' },
    { l = 's' },
    { l = 'd' },
    { l = 'f' },
    { l = 'g' },
}

function switch_slot(slot)
    slots[curr_slot].buf = vim.api.nvim_get_current_buf()
    if slots[slot].buf == nil then
        slots[slot].buf = slots[curr_slot]
    else
        vim.api.nvim_win_set_buf(0, slots[slot].buf)
    end
    curr_slot = slot
    -- vim.cmd("redrawtabline")
end

for i, slot in ipairs(slots) do
    vim.keymap.set("n", "'"..slot.l, function() switch_slot(i) end)
end

-- vim.opt.tabline = "%!v:lua.PillTabline()"
-- vim.opt.showtabline = 2
-- function _G.PillTabline()
--     local s = ""
--     for i, slot in ipairs(slots) do
--         local is_active = (i == curr_slot)
--         local hl = is_active and "%#TabLine#" or "%#TabLineFill#"
--         s = s .. hl .. " " .. slot.l .. " " .. "%#TabLineFill#"
--     end
--
--     return s
-- end
