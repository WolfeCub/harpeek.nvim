# Har(and other quick access lists)peek

A simple plugin that allows you to _peek_ at your harpoon/grapple/arrow lists.
The look was heavily inspired by [bufpin.nvim](https://github.com/0x7a7a/bufpin.nvim).

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

The public API of harpeek is very simple:

```lua
-- You can toggle the visibility of the window with:
require('harpeek').toggle()
-- if you need more granular control you can open/close the preview window with:
require('harpeek').open()
require('harpeek').close()
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
})
```
