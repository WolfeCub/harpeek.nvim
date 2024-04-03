---@type harpeek.source
return {
    plugin_name = 'harpoon',
    get_list = function()
        local harpoon = require('harpoon')

        local list = {}
        for _, item in ipairs(harpoon:list().items) do
            table.insert(list, item.value)
        end
        return list
    end,
    register_listener = function()
        local harpoon = require('harpoon')

        local fun = function()
            Harpeek._update()
        end

        harpoon:extend({
            ADD = fun,
            REMOVE = fun,
            REORDER = fun,
            LIST_CREATED = fun,
        })
    end,
}
