---@type harpeek.source
return {
    plugin_name = 'arrow',
    get_list = function()
        return vim.g.arrow_filenames
    end,
    register_listener = function()
        vim.api.nvim_create_autocmd('User', {
            pattern = 'ArrowUpdate',
            callback = function()
                if Harpeek._window then
                    Harpeek.open()
                end
            end,
        })
    end,
}
