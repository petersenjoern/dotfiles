return {
    "folke/which-key.nvim",
    event = "VeryLazy",

    config = function()
        local wk = require("which-key")

        wk.setup({
            preset = "modern",
            delay = 200,
            icons = {
                breadcrumb = "»",
                separator = "➜",
                group = "+",
            },
            win = {
                border = "rounded",
                padding = { 1, 2 },
            },
        })

        -- Register all keymaps with descriptions
        wk.add({
            -- Groups
            { "<leader>d", group = "debug" },
            { "<leader>t", group = "test" },
            { "<leader>p", group = "project" },
            { "<leader>e", group = "error handling (Go)" },
            { "<leader>h", group = "git hunks" },
            { "<leader>s", group = "search/replace" },

            -- From remap.lua
            { "<leader>pv", desc = "File explorer (netrw)" },
            { "<leader>y", desc = "Yank to clipboard" },
            { "<leader>Y", desc = "Yank line to clipboard" },
            { "<leader>f", desc = "Format buffer" },
            { "<leader>k", desc = "Next location list" },
            { "<leader>j", desc = "Prev location list" },
            { "<leader>q", desc = "Close quickfix" },
            { "<leader>x", desc = "Make file executable" },
            { "<leader><leader>", desc = "Source file" },
            { "<leader>zig", desc = "Restart LSP" },
            { "<leader>ca", desc = "Cellular automaton" },
            { "<leader>ct", desc = "Toggle cloak" },
            { "<leader>D", desc = "Delete to void register" },

            -- Go error handling
            { "<leader>ee", desc = "if err != nil { return }" },
            { "<leader>ea", desc = "assert.NoError()" },
            { "<leader>ef", desc = "if err != nil { log.Fatalf }" },
            { "<leader>el", desc = "if err != nil { logger.Error }" },

            -- From telescope.lua (guessing based on common patterns)
            { "<leader>pf", desc = "Find files" },
            { "<leader>ps", desc = "Grep search" },

            -- From harpoon
            { "<leader>a", desc = "Harpoon add file" },

            -- From gitsigns (hunks)
            { "<leader>hp", desc = "Preview hunk" },
            { "<leader>hb", desc = "Blame line" },

            -- From Comment.nvim (g prefix, not leader)
            { "gc", group = "comment (line)" },
            { "gcc", desc = "Toggle line comment" },
            { "gcO", desc = "Comment above" },
            { "gco", desc = "Comment below" },
            { "gcA", desc = "Comment end of line" },
            { "gb", group = "comment (block)" },
            { "gbc", desc = "Toggle block comment" },

            -- From vim-test
            { "<leader>tn", desc = "Test nearest" },
            { "<leader>tf", desc = "Test file" },
            { "<leader>ts", desc = "Test suite" },
            { "<leader>tl", desc = "Test last" },
            { "<leader>tv", desc = "Visit test file" },

            -- From dap.lua
            { "<leader>db", desc = "Toggle breakpoint" },
            { "<leader>dB", desc = "Conditional breakpoint" },
            { "<leader>dl", desc = "Log point" },
            { "<leader>dc", desc = "Continue/Start" },
            { "<leader>do", desc = "Step over" },
            { "<leader>di", desc = "Step into" },
            { "<leader>dO", desc = "Step out" },
            { "<leader>dr", desc = "Run to cursor" },
            { "<leader>dx", desc = "Terminate" },
            { "<leader>dR", desc = "Restart" },
            { "<leader>du", desc = "Toggle UI" },
            { "<leader>de", desc = "Eval expression" },
            { "<leader>dp", desc = "Open REPL" },
            { "<leader>dL", desc = "List breakpoints" },
            { "<leader>dC", desc = "Clear breakpoints" },

            -- From other.nvim (test/impl toggle)
            { "<leader>o", desc = "Open other file (test/impl)" },
            { "<leader>O", desc = "Open other file in vsplit" },

            -- From nvim-spectre (search/replace)
            { "<leader>sr", desc = "Search & Replace (Spectre)" },
            { "<leader>sw", desc = "Search current word" },
            { "<leader>sp", desc = "Search in current file" },

            -- From nvim-surround
            { "ys", desc = "Add surround" },
            { "cs", desc = "Change surround" },
            { "ds", desc = "Delete surround" },

            -- From treesitter-textobjects (selection)
            { "af", desc = "Select around function" },
            { "if", desc = "Select inner function" },
            { "ac", desc = "Select around class" },
            { "ic", desc = "Select inner class" },
            { "aa", desc = "Select around argument" },
            { "ia", desc = "Select inner argument" },

            -- From treesitter-textobjects (movement)
            { "]m", desc = "Next function start" },
            { "[m", desc = "Prev function start" },
            { "]M", desc = "Next function end" },
            { "[M", desc = "Prev function end" },
            { "]c", desc = "Next class start" },
            { "[c", desc = "Prev class start" },
            { "]C", desc = "Next class end" },
            { "[C", desc = "Prev class end" },
        })
    end,
}
