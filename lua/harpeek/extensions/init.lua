---@class harpeek.source
---@field plugin_name string
---@field get_list fun(): string[]
---@field register_listener fun(): nil


local function has(module)
    local exists, _ = pcall(require, module)
    return exists
end


local extensions = {
    require('harpeek.extensions.grapple'),
    require('harpeek.extensions.harpoon'),
}

for _, ext in ipairs(extensions) do
    if has(ext.plugin_name) then
        return ext
    end
end

vim.notify(
    'Harpeek could not detect any supported plugins. Please ensure they\'re requirable before harpeek setup is called.',
    vim.log.levels.ERROR
)
