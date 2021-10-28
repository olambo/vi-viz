 # vi-viz

## Summary
vi-viz for Neovim

vi-viz alows you to visually expand or contract a region of text using a key combination. Once you have visually selected your region you can surround your text with quotes, brackets etc

### Example
If you have a line of text including the phrase in quotes "Hi There", you can select all the text and quotes by placing your cursor inside the quotes and pressing the expansion key a couple of times. 

* `<cr>` below is the return key. 
* While the text and quotes are selected type `r'<cr>`  This will change the text to - 'Hi There'
* Select the text and quotes and delete the quotes type `r<cr>` This will change the text to - Hi There
* To put some parentheses around the text, visually select Hi There and type `r(<cr>` - yup, you get (Hi There)

### Dependencies

vi-viz is written in Lua and requires Neovim. The plugin works with VSCode Neovim.

### Install

For example, using Vim-Plug: <br/> 
Plug 'olambo/vi-viz'

### Keymappings - change to your preferences

```
:lua <<EOF

local map = vim.api.nvim_set_keymap
-- to start off from normal mode
map('n', '<right>',   "<cmd>lua require('vi-viz').vizInit()<CR>",          {noremap = true})
-- expand and contract
map('x', '<right>',   "<cmd>lua require('vi-viz').vizExpand()<CR>",        {noremap = true})
map('x', '<left>',    "<cmd>lua require('vi-viz').vizContract()<CR>",      {noremap = true})
-- expand and contract by 1 char either side
map('x', '=',         "<cmd>lua require('vi-viz').vizExpand1Chr()<CR>",    {noremap = true})
map('x', '-',         "<cmd>lua require('vi-viz').vizContract1Chr()<CR>",  {noremap = true})
-- good use for the r key in visual mode
map('x', 'r',         "<cmd>lua require('vi-viz').vizPattern()<CR>",       {noremap = true})
-- nice to have to get dot repeat on single words
map('x', 'c',         "<cmd>lua require('vi-viz').vizChange()<CR>",        {noremap = true})
-- nice to have to insert before and after
map('x', 'ii',        "<cmd>lua require('vi-viz').vizInsert()<CR>",        {noremap = true})
map('x', 'aa',        "<cmd>lua require('vi-viz').vizAppend()<CR>",        {noremap = true})

EOF
```
