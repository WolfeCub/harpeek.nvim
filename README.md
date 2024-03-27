# Har(and other quick access lists)peek

A simple plugin that allows you to _peek_ at your harpoon/grapple/arrow lists.
The look was heavily inspired by [bufpin.nvim](https://github.com/0x7a7a/bufpin.nvim).

![harpeek-demo](https://github.com/WolfeCub/harpeek.nvim/assets/1369773/5ef08444-04e3-4ecf-ab8d-5bcff8e1bd41)

## Installation

Using lazy.nvim

```lua
{
    'WolfeCub/harpeek.nvim',
    config = function()
        require('harpeek').setup()
    end
}
```

## Usage
The public API of harpeek is very simple:

```lua
-- You can toggle the visibility of the window with:
require('harpeek').toeggle()
-- if you need more granular control you can open/close the preview window with:
require('harpeek').open()
require('harpeek').close()
```

Harpeek will automatically detect if you have harpoon or grapple installed and use the appropriate list.


### Default options

```lua
require('harpeek').setup({
    hl_group = 'Error', -- This group will be used to highlight your current active buffer
})
```
