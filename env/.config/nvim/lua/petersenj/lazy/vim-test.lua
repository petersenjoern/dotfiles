return {
    "vim-test/vim-test",
    dependencies = {
        "preservim/vimux", -- Optional: run tests in tmux pane
    },
    config = function()
        -- Use pytest for Python tests
        vim.g["test#python#runner"] = "pytest"

        -- Run tests in a terminal split (default strategy)
        -- Options: "neovim", "vimux", "dispatch", "terminal"
        vim.g["test#strategy"] = "neovim"

        -- pytest options: verbose output, short traceback
        vim.g["test#python#pytest#options"] = "-v --tb=short"

        -- Keymaps for running tests
        -- Run nearest test to cursor | Trigger: SPACE + t + n
        vim.keymap.set("n", "<leader>tn", "<cmd>TestNearest<CR>", { desc = "Run nearest test" })
        -- Run all tests in current file | Trigger: SPACE + t + f
        vim.keymap.set("n", "<leader>tf", "<cmd>TestFile<CR>", { desc = "Run tests in file" })
        -- Run entire test suite | Trigger: SPACE + t + s
        vim.keymap.set("n", "<leader>ts", "<cmd>TestSuite<CR>", { desc = "Run test suite" })
        -- Re-run last test | Trigger: SPACE + t + l
        vim.keymap.set("n", "<leader>tl", "<cmd>TestLast<CR>", { desc = "Run last test" })
        -- Go to last test file | Trigger: SPACE + t + v
        vim.keymap.set("n", "<leader>tv", "<cmd>TestVisit<CR>", { desc = "Visit last test file" })
    end,
}
