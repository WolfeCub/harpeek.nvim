local ext = require('harpeek.extensions')

Harpeek = {}

---@class harpeek.settings
---@field hl_group string? The highlight group to use for the currently selected buffer

---@type harpeek.settings
local default_settings = {
    hl_group = 'Error',
}

---@param opts harpeek.settings?
function Harpeek.setup(opts)
    if not opts then
        opts = {}
    end
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

local function _dir_name_modify(dirname)
    local cwd = vim.fn.getcwd()
    if dirname:find('oil://') then
        dirname = dirname:gsub( 'oil://', '')
    end
    if dirname:find(cwd) then
        return './' .. dirname:gsub( cwd..'/', '')
    end
    return dirname
end

function Harpeek.open()
    local contents = {}
    local longest_line = 0
    local line = ''
    local list = ext.get_list()
    for i, path in ipairs(list) do
        line = vim.fn.fnamemodify(path, ':t')

        if line:len() == 0 then
            line = _dir_name_modify(path)
        end

        table.insert(contents, i .. ' ' .. line)

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
            Harpeek._hlns = vim.api.nvim_buf_add_highlight(Harpeek._buffer, 0, 'Error', i-1, 0, -1)
        end
    end

    local size = vim.api.nvim_list_uis()[1]

    if Harpeek._window then
        vim.api.nvim_win_set_height(Harpeek._window, #contents)
        vim.api.nvim_win_set_width(Harpeek._window, longest_line)
    else
        if #contents == 0 then
            vim.notify("No marks are available")
        else
            Harpeek._window = vim.api.nvim_open_win(buff, false, {
                relative = 'win',
                focusable = false,
                row = size.height * 0.2,
                col = size.width,
                width = longest_line,
                height = #contents,
                border = { '╭', '─', '─', ' ', '─', '─', '╰', '│' },
                style = 'minimal'
            })
        end
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
