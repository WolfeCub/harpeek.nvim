---@type harpeek.source
return {
    plugin_name = 'grapple',
    get_list = function()
        local grapple = require('grapple')

        local list = {}
        for _, item in ipairs(grapple.tags()) do
            table.insert(list, item.path)
        end
        return list
    end,
    register_listener = function()
        vim.api.nvim_create_autocmd('User', {
            pattern = 'GrappleUpdate',
            callback = function()
                if Harpeek._window then
                    Harpeek.open()
                end
            end,
        })
    end,
}
