local ext = require('harpeek.extensions')

Harpeek = {}

---@class harpeek.settings
---@field hl_group string? The highlight group to use for the currently selected buffer
---@field winopts table<string, any>? Overrides that will be passed to `nvim_open_win`
---@field format harpeek.format How each item will be displayed. 'filename' will show just the tail. 'relative' will show the entire path relative to cwd. 'shortened' will show relative with single letters for the dir.

---@alias harpeek.format 'filename' | 'relative' | 'shortened' | fun(path: string, index: number): string

---@type harpeek.settings
local default_settings = {
    hl_group = 'Error',
    winopts = {},
    format = 'filename',
}

---@param opts harpeek.settings?
function Harpeek.setup(opts)
    if not opts then
        opts = {}
    end

    ---@type harpeek.settings
    Harpeek._settings = vim.tbl_extend('force', default_settings, opts)

    ext.register_listener()

    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        callback = function()
            if Harpeek._window then
                Harpeek.open()
            end
        end,
    })
end

local function get_buffer()
    if Harpeek._buffer then
        return Harpeek._buffer
    else
        local buff = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(buff, '*preview-tmp*')
        Harpeek._buffer = buff
        return buff
    end
end

---@param path string
local function format_item(path, index)
    if type(Harpeek._settings.format) == 'function' then
        return Harpeek._settings.format(path, index)
    end

    local format = ''
    if Harpeek._settings.format == 'filename' then
        format = vim.fn.fnamemodify(path, ':t')
    else
        local relative = vim.fn.fnamemodify(path, ':.')
        if Harpeek._settings.format == 'relative' then
            format = relative
        elseif Harpeek._settings.format == 'shortened' then
            format = vim.fn.pathshorten(relative)
        end
    end

    return index .. ' ' .. format
end

function Harpeek.open()
    local contents = {}
    local longest_line = 0
    local list = ext.get_list()
    for i, path in ipairs(list) do
        local line = format_item(path, i)
        table.insert(contents, line)

        if line:len() > longest_line then
            longest_line = line:len()
        end
    end

    local buff = get_buffer()
    vim.api.nvim_buf_set_lines(buff, 0, -1, true, contents)


    if Harpeek._buffer and Harpeek._hlns then
        vim.api.nvim_buf_clear_namespace(Harpeek._buffer, Harpeek._hlns, 0, -1)
    end

    for i, item in ipairs(list) do
        if vim.fn.expand('%:p') == vim.fn.fnamemodify(item, ':p') then
            Harpeek._hlns = vim.api.nvim_buf_add_highlight(Harpeek._buffer, 0, Harpeek._settings.hl_group, i - 1, 0, -1)
        end
    end

    local size = vim.api.nvim_list_uis()[1]

    if Harpeek._window then
        vim.api.nvim_win_set_height(Harpeek._window, #contents)
        vim.api.nvim_win_set_width(Harpeek._window, longest_line)
    else
        local winopts = {
            relative = 'win',
            focusable = false,
            row = size.height * 0.2,
            col = size.width,
            width = longest_line,
            height = #contents,
            border = { '╭', '─', '─', ' ', '─', '─', '╰', '│' },
            style = 'minimal'
        }
        Harpeek._window = vim.api.nvim_open_win(buff, false, vim.tbl_extend('force', winopts, Harpeek._settings.winopts))
    end
end

function Harpeek.close()
    if Harpeek._window then
        vim.api.nvim_win_close(Harpeek._window, true)
        Harpeek._window = nil
    end
end

function Harpeek.toggle()
    if Harpeek._window then
        Harpeek.close()
    else
        Harpeek.open()
    end
end

return Harpeek
