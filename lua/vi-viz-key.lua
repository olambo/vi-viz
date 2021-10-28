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
