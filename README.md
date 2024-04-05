# Har(and other quick access lists)peek

A simple plugin that allows you to _peek_ at your harpoon/grapple/arrow lists via a floating window or tabline replacement.

![harpeek-demo](https://github.com/WolfeCub/harpeek.nvim/assets/1369773/5ef08444-04e3-4ecf-ab8d-5bcff8e1bd41)

## Quick Start

Using lazy.nvim

```lua
{
    'WolfeCub/harpeek.nvim',
    config = function()
        require('harpeek').setup()
    end
}
```

You may optionally specify `branch = beta` to get features as they're being developed. **IMPORTANT** this is an active
development branch and may break at any time.

The public API of harpeek is very simple:

```lua
-- You can toggle the visibility of the window with:
require('harpeek').toggle()
-- if you need more granular control you can open/close the preview window with:
require('harpeek').open()
require('harpeek').close()


-- You can also pass an optional settings to open and toggle functions:
require('harpeek').toggle({
    hl_group = 'Error',
    format = 'relative',
})
require('harpeek').open({
    winopts = {
        row = 10,
        col = 10,
        border = 'none',
    }
})
```

Harpeek will automatically detect if you have harpoon or grapple installed and use the appropriate list.

## Advanced Setup

```lua
require('harpeek').setup({
    -- You can replace the hightlight group used on the currently selected buffer
    hl_group = 'Error',
    -- You can override any window options. For example here we set a different position & border.
    winopts = {
        row = 10,
        col = 10,
        border = 'rounded',
    },
    -- How each item will be displayed:
    -- 'filename' will show just the tail (default)
    -- 'relative' will show the entire path relative to cwd
    -- 'shortened' will show relative with single letters for the dir
    format = 'relative',
    -- Alternatively format can be a function that returns a custom format for each line
    format = function(path, index)
        return '[' .. index .. '] - ' .. path
    end
    -- Don't show the window if you don't have any marks. It will automatically (re)open if a mark is created.
    hide_on_empty = true,
    -- Replace the tabline with your list items. This can be used in place or alongside the floating window.
    tabline = true,
})
```

## Inspiration

- [bufpin.nvim](https://github.com/0x7a7a/bufpin.nvim)
