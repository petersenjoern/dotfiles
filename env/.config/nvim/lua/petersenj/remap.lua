-- Set space as the leader key
vim.g.mapleader = " "
-- Open file explorer | Trigger: SPACE + p + v
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Move selected lines down in visual mode | Trigger: J (in visual mode)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
-- Move selected lines up in visual mode | Trigger: K (in visual mode)
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Run Plenary test file | Trigger: SPACE + t + f
vim.api.nvim_set_keymap("n", "<leader>tf", "<Plug>PlenaryTestFile", { noremap = false, silent = false })

-- Join lines but keep cursor position (mark z, join, return to mark) | Trigger: J (in normal mode)
vim.keymap.set("n", "J", "mzJ`z")
-- Half page down and center cursor | Trigger: CTRL + d
vim.keymap.set("n", "<C-d>", "<C-d>zz")
-- Half page up and center cursor | Trigger: CTRL + u
vim.keymap.set("n", "<C-u>", "<C-u>zz")
-- Next search result and center cursor | Trigger: n
vim.keymap.set("n", "n", "nzzzv")
-- Previous search result and center cursor | Trigger: N (SHIFT + n)
vim.keymap.set("n", "N", "Nzzzv")
-- Auto-indent paragraph and restore cursor position | Trigger: = + a + p
vim.keymap.set("n", "=ap", "ma=ap'a")
-- Restart LSP server | Trigger: SPACE + z + i + g
vim.keymap.set("n", "<leader>zig", "<cmd>LspRestart<cr>")

-- greatest remap ever
-- Paste over selection without losing clipboard content | Trigger: SPACE + p (in visual mode)
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
-- Copy to system clipboard | Trigger: SPACE + y (normal/visual mode)
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
-- Copy line to system clipboard | Trigger: SPACE + Y (SHIFT + y)
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Delete without copying to clipboard (void register) | Trigger: SPACE + d (normal/visual mode)
vim.keymap.set({ "n", "v" }, "<leader>d", "\"_d")

-- This is going to get me cancelled
-- Make Ctrl+C behave like Escape in insert mode | Trigger: CTRL + c (in insert mode)
vim.keymap.set("i", "<C-c>", "<Esc>")

-- Disable Q (ex mode) | Trigger: Q (disabled)
vim.keymap.set("n", "Q", "<nop>")
-- Open tmux sessionizer | Trigger: CTRL + f
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
-- Format current buffer | Trigger: SPACE + f
vim.keymap.set("n", "<leader>f", function()
    require("conform").format({ bufnr = 0 })
end)

-- Next quickfix item and center cursor | Trigger: CTRL + k
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
-- Previous quickfix item and center cursor | Trigger: CTRL + j
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
-- Next location list item and center cursor | Trigger: SPACE + k
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
-- Previous location list item and center cursor | Trigger: SPACE + j
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Search and replace word under cursor | Trigger: SPACE + s
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
-- Make current file executable | Trigger: SPACE + x
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Insert Go error handling with return | Trigger: SPACE + e + e
vim.keymap.set(
    "n",
    "<leader>ee",
    "oif err != nil {<CR>}<Esc>Oreturn err<Esc>"
)

-- Insert Go test assertion for no error | Trigger: SPACE + e + a
vim.keymap.set(
    "n",
    "<leader>ea",
    "oassert.NoError(err, \"\")<Esc>F\";a"
)

-- Insert Go error handling with log.Fatalf | Trigger: SPACE + e + f
vim.keymap.set(
    "n",
    "<leader>ef",
    "oif err != nil {<CR>}<Esc>Olog.Fatalf(\"error: %s\\n\", err.Error())<Esc>jj"
)

-- Insert Go error handling with logger.Error | Trigger: SPACE + e + l
vim.keymap.set(
    "n",
    "<leader>el",
    "oif err != nil {<CR>}<Esc>O.logger.Error(\"error\", \"error\", err)<Esc>F.;i"
)

-- Start cellular automaton "make it rain" animation | Trigger: SPACE + c + a
vim.keymap.set("n", "<leader>ca", function()
    require("cellular-automaton").start_animation("make_it_rain")
end)

-- Source current file (reload configuration) | Trigger: SPACE + SPACE
vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)
