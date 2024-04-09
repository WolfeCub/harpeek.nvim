local ext = require('harpeek.extensions')

Harpeek = {}

---@class harpeek.settings
---@field hl_group string? The highlight group to use for the currently selected buffer
---@field winopts table<string, any>? Overrides that will be passed to `nvim_open_win`
---@field format harpeek.format? How each item will be displayed. 'filename' will show just the tail. 'relative' will show the entire path relative to cwd. 'shortened' will show relative with single letters for the dir.
---@field hide_on_empty boolean? Hide the window if you have no marks. The window will automatically open if a mark is created.
---@field number_items boolean? Show the position next to each item in the list.
---@field tabline boolean? Replace the tabline with your list items. This can be used in place or alongside the floating window.

---@alias harpeek.format 'filename' | 'relative' | 'shortened' | fun(path: string, index: number): string

---@type harpeek.settings
local default_settings = {
    hl_group = 'Error',
    winopts = {},
    format = 'filename',
    hide_on_empty = false,
    number_items = true,
    tabline = false,
}

---@type harpeek.settings
Harpeek._open_opts = nil

local function set_tabline()
    vim.o.tabline = '%!v:lua.harpeek_tabline()'
end

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
                Harpeek._update()
            end
        end,
    })

    if Harpeek._settings.tabline then
        set_tabline()
    end
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

-- A window is considered hidden if `Harpeek._window` is `nil` but we still have open opts.
---@return boolean
local function is_hidden()
    return Harpeek._window == nil and Harpeek._open_opts ~= nil
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
---@param index number
---@param format harpeek.format
---@param show_num boolean
local function format_item(path, index, format, show_num)
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
    local formatted_line = ''
    if format == 'filename' then
        formatted_line = vim.fn.fnamemodify(path, ':t') .. suffix
    else
        local relative = vim.fn.fnamemodify(path .. suffix, ':.')
        if #relative == 0 then
            formatted_line = '.'
        elseif format == 'relative' then
            formatted_line = relative
        elseif format == 'shortened' then
            formatted_line = vim.fn.pathshorten(vim.fn.fnamemodify(path, ':.')) .. suffix
        end
    end

    if show_num then
        formatted_line =  index .. ' ' .. formatted_line
    end

    return formatted_line
end

function Harpeek._update()
    if Harpeek._settings.tabline then
        set_tabline()
    end
    if Harpeek._window or is_hidden() then
        Harpeek.open(Harpeek._open_opts)
    end
end

---@param path string
---@return boolean
local function file_is_current_buffer(path)
    return vim.fn.expand('%:p') == vim.fn.fnamemodify(path, ':p')
end

---@param opts harpeek.settings?
function Harpeek.open(opts)
    Harpeek._open_opts = vim.tbl_extend('force', Harpeek._settings, opts or {})

    local contents = {}
    local longest_line = 0
    local list = ext.get_list()

    for i, path in ipairs(list) do
        local line = format_item(path, i, Harpeek._open_opts.format, Harpeek._open_opts.number_items)
        table.insert(contents, line)

        if line:len() > longest_line then
            longest_line = line:len()
        end
    end

    if #list == 0 then
        if Harpeek._window and Harpeek._open_opts.hide_on_empty then
            local win = Harpeek._window
            Harpeek._window = nil
            vim.api.nvim_win_hide(win)
            return
        end

        contents = {"No marks"}
        longest_line = contents[1]:len()
    end

    local buff = get_buffer()
    vim.api.nvim_buf_set_lines(buff, 0, -1, true, contents)


    if Harpeek._buffer and Harpeek._hlns then
        vim.api.nvim_buf_clear_namespace(Harpeek._buffer, Harpeek._hlns, 0, -1)
    end

    for i, item in ipairs(list) do
        if file_is_current_buffer(item) then
            Harpeek._hlns = vim.api.nvim_buf_add_highlight(Harpeek._buffer, 0, Harpeek._open_opts.hl_group, i - 1, 0, -1)
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
        Harpeek._window = vim.api.nvim_open_win(buff, false, vim.tbl_extend('force', winopts, Harpeek._open_opts.winopts))
    end
end

function Harpeek.close()
    if Harpeek._window then
        vim.api.nvim_win_close(Harpeek._window, true)
        Harpeek._window = nil
        Harpeek._open_opts = nil
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

-- Generates a tabline string that displays your harpeek buffers in the tabline
function _G.harpeek_tabline()
    local list = ext.get_list()

    local contents = {}
    for i, path in ipairs(list) do
        local line = format_item(path, i, Harpeek._settings.format, Harpeek._settings.number_items)

        local group = '%#TabLine#'
        if file_is_current_buffer(path) then
            group ='%#TabLineSel#'
        end
        table.insert(contents, group .. ' ' .. line .. ' ')
    end
    table.insert(contents, '%#TabLineFill#%T')

    return table.concat(contents)
end

return Harpeek
