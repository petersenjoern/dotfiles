return {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    opts = {
        max_count = 2,
        disable_mouse = false,
        restriction_mode = "block",
        disabled_filetypes = {
            "NvimTree",
            "TelescopePrompt",
            "harpoon",
            "help",
            "qf",
            "netrw",
            "lazy",
            "mason",
        },
        hint = true,
        notification = true,
        restricted_keys = {
            ["h"] = { "n", "x" },
            ["j"] = { "n", "x" },
            ["k"] = { "n", "x" },
            ["l"] = { "n", "x" },
            ["w"] = { "n", "x" },
            ["W"] = { "n", "x" },
            ["b"] = { "n", "x" },
            ["B"] = { "n", "x" },
        },
        disabled_keys = {
            ["<Up>"]    = { "", "i", "c" },
            ["<Down>"]  = { "", "i", "c" },
            ["<Left>"]  = { "", "i", "c" },
            ["<Right>"] = { "", "i", "c" },
        },
        hints = {
            ["ww"] = {
                message = function() return "Use f{char}/F{char} + ;/, for in-line navigation" end,
                length = 2,
            },
            ["WW"] = {
                message = function() return "Use f{char}/F{char} + ;/, for in-line navigation" end,
                length = 2,
            },
            ["bb"] = {
                message = function() return "Use F{char} backward; bi to insert at word start" end,
                length = 2,
            },
            ["BB"] = {
                message = function() return "Use F{char} backward; Bi to insert at WORD start" end,
                length = 2,
            },
            -- Two keys when one exists
            ["d%$"] = {
                message = function() return "Use D instead of d$" end,
                length = 2,
            },
            ["y%$"] = {
                message = function() return "Use Y instead of y$" end,
                length = 2,
            },
            ["c%$"] = {
                message = function() return "Use C instead of c$" end,
                length = 2,
            },
            ["0i"] = {
                message = function() return "Use I instead of 0i" end,
                length = 2,
            },
            ["%^i"] = {
                message = function() return "Use I instead of ^i" end,
                length = 2,
            },
            ["%$a"] = {
                message = function() return "Use A instead of $a" end,
                length = 2,
            },
        },
    },
    config = function(_, opts)
        require("hardtime").setup(opts)

        vim.api.nvim_create_autocmd("VimEnter", {
            once = true,
            callback = function()
                vim.defer_fn(function()
                    vim.notify(
                        table.concat({
                            "Drills for this session:",
                            "  • bi  — insert at start of word (vs. ciw + retype)",
                            "  • Bi  — insert at start of WORD",
                            "  • f{char}/F{char} + ;/, — in-line jumps (vs. spamming w)",
                        }, "\n"),
                        vim.log.levels.INFO,
                        { title = "nvim navigation" }
                    )
                end, 500)
            end,
        })
    end,
    keys = {
        { "<leader>ht", "<cmd>Hardtime toggle<cr>", desc = "Toggle Hardtime" },
    },
}
