local ext = require('harpeek.extensions')

M = {}

---@class harpeek.settings
---@field hl_group string? The highlight group to use for the currently selected buffer

---@type harpeek.settings
local default_settings = {
    hl_group = 'Error',
}

---@param opts harpeek.settings?
function M.setup(opts)
    if not opts then
        opts = {}
    end
    M._settings = vim.tbl_extend('force', default_settings, opts)

    ext.register_listener()

    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        callback = function()
            if M._window then
                M.open()
            end
        end,
    })
end

local function get_buffer()
    if M._buffer then
        return M._buffer
    else
        local buff = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(buff, '*preview-tmp*')
        M._buffer = buff
        return buff
    end
end

function M.open()
    local contents = {}
    local longest_line = 0
    local list = ext.get_list()
    for i, path in ipairs(list) do
        local line = i .. ' ' .. vim.fn.fnamemodify(path, ':t')
        table.insert(contents, line)

        if line:len() > longest_line then
            longest_line = line:len()
        end

    end

    local buff = get_buffer()
    vim.api.nvim_buf_set_lines(buff, 0, -1, true, contents)


    if M._buffer and M._hlns then
        vim.api.nvim_buf_clear_namespace(M._buffer, M._hlns, 0, -1)
    end

    for i, item in ipairs(list) do
        if vim.fn.expand('%:p') == vim.fn.fnamemodify(item, ':p') then
            M._hlns = vim.api.nvim_buf_add_highlight(M._buffer, 0, 'Error', i-1, 0, -1)
        end
    end

    local size = vim.api.nvim_list_uis()[1]

    if M._window then
        vim.api.nvim_win_set_height(M._window, #contents)
        vim.api.nvim_win_set_width(M._window, longest_line)
    else
        M._window = vim.api.nvim_open_win(buff, false, {
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

function M.close()
    if M._window then
        vim.api.nvim_win_close(M._window, true)
        M._window = nil
    end
end

return M
