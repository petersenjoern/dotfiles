return {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>sr", function() require("spectre").open() end, desc = "Search & Replace (Spectre)" },
        { "<leader>sw", function() require("spectre").open_visual({ select_word = true }) end, desc = "Search current word" },
        { "<leader>sp", function() require("spectre").open_file_search({ select_word = true }) end, desc = "Search in current file" },
    },
    config = function()
        require("spectre").setup({
            highlight = {
                search = "SpectreSearch",
                replace = "SpectreReplace",
            },
            mapping = {
                ["send_to_qf"] = {
                    map = "<leader>q",
                    cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
                    desc = "send all items to quickfix",
                },
            },
        })
    end,
}
