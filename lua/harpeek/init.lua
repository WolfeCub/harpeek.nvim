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
---@return string?
local function split_oil_dir(path)
    if path:sub(1, 6) ~= 'oil://' then
        return nil
    end

    if path:sub(-1, -1) == '/' then
        return path:sub(7, -2)
    else
        return path:sub(7, -1)
    end
end

---@param path string
---@param format harpeek.format
local function format_item(path, index, format)
    if type(format) == 'function' then
        return format(path, index)
    end

    local oil_path = split_oil_dir(path)
    local suffix = ''
    if oil_path then
        path = oil_path
        suffix = '/'
    end

    -- TODO: This logic is pretty opaque. I could probably do something nicer.
    local postfix = ''
    if format == 'filename' then
        postfix = vim.fn.fnamemodify(path, ':t') .. suffix
    else
        local relative = vim.fn.fnamemodify(path .. suffix, ':.')
        if #relative == 0 then
            postfix = '.'
        elseif format == 'relative' then
            postfix = relative
        elseif format == 'shortened' then
            postfix = vim.fn.pathshorten(vim.fn.fnamemodify(path, ':.')) .. suffix
        end
    end

    return index .. ' ' .. postfix
end

---@param opts harpeek.settings?
function Harpeek.open(opts)
    if not opts then
        opts = Harpeek._settings
    end
    opts = vim.tbl_extend('force', Harpeek._settings, opts)

    local contents = {}
    local longest_line = 0
    local list = ext.get_list()
    if #list == 0 then
        vim.notify("No marks")
        return
    end

    for i, path in ipairs(list) do
        local line = format_item(path, i, opts.format)
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
            Harpeek._hlns = vim.api.nvim_buf_add_highlight(Harpeek._buffer, 0, opts.hl_group, i - 1, 0, -1)
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
        Harpeek._window = vim.api.nvim_open_win(buff, false, vim.tbl_extend('force', winopts, opts.winopts))
    end
end

function Harpeek.close()
    if Harpeek._window then
        vim.api.nvim_win_close(Harpeek._window, true)
        Harpeek._window = nil
    end
end

---@param opts harpeek.settings?
function Harpeek.toggle(opts)
    if Harpeek._window then
        Harpeek.close()
    else
        Harpeek.open(opts)
    end
end

return Harpeek
