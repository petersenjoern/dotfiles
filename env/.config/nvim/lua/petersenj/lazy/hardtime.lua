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
    },
    keys = {
        { "<leader>ht", "<cmd>Hardtime toggle<cr>", desc = "Toggle Hardtime" },
    },
}
