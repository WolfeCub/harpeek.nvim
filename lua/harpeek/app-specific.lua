local function srequire(module)
    local exists, m = pcall(require, module)
    if exists then
        return m
    end
end

local grapple = srequire('grapple')
local harpoon = srequire('harpoon')

M = {}

local function grapple_get_list()
    local list = {}
    for _, item in ipairs(grapple.tags()) do
        table.insert(list, item.path)
    end
    return list
end

local function harpoon_get_list()
    local list = {}
    for _, item in ipairs(harpoon:list().items) do
        table.insert(list, item.value)
    end
    return list
end

function M.get_list()
    if harpoon then
        return harpoon_get_list()
    elseif grapple then
        return grapple_get_list()
    end
end

local function harpoon_register_listener()
    local fun = function()
        if M._window then
            M.open()
        end
    end

    harpoon:extend({
        ADD = fun,
        REMOVE = fun,
        REORDER = fun,
        LIST_CREATED = fun,
    })
end

local function grapple_register_listener()
    vim.api.nvim_create_autocmd('User', {
        pattern = 'GrappleUpdate',
        callback = function()
            if M._window then
                M.open()
            end
        end,
    })
end

function M.register_listener()
    if harpoon then
        harpoon_register_listener()
    elseif grapple then
        grapple_register_listener()
    end
end

return M
