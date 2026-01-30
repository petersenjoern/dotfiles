return {
    "rgroli/other.nvim",
    keys = {
        { "<leader>o", "<cmd>Other<cr>", desc = "Open other file (test/impl)" },
        { "<leader>O", "<cmd>OtherVSplit<cr>", desc = "Open other file in vsplit" },
    },
    config = function()
        require("other-nvim").setup({
            mappings = {
                -- Go
                {
                    pattern = "(.*).go$",
                    target = "%1_test.go",
                    context = "test",
                },
                {
                    pattern = "(.*)_test.go$",
                    target = "%1.go",
                    context = "implementation",
                },
                -- Python: same directory
                {
                    pattern = "(.*)/([^/]+).py$",
                    target = "%1/test_%2.py",
                    context = "test",
                },
                {
                    pattern = "(.*)/test_([^/]+).py$",
                    target = "%1/%2.py",
                    context = "implementation",
                },
                -- Python: tests/ subdirectory
                {
                    pattern = "(.*)/([^/]+).py$",
                    target = "%1/tests/test_%2.py",
                    context = "test",
                },
                {
                    pattern = "(.*)/tests/test_([^/]+).py$",
                    target = "%1/%2.py",
                    context = "implementation",
                },
            },
        })
    end,
}
