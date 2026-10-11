return {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    opts = {},
    keys = {
        { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "History of this file" },
        { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "History of the repo" },
        -- Right pane is the editable working tree, so you fix the text without leaving the diff
        {
            "<leader>gd",
            function()
                vim.ui.input({ prompt = "DiffviewOpen ", default = "HEAD~5" }, function(rev)
                    if rev and rev ~= "" then vim.cmd("DiffviewOpen " .. rev) end
                end)
            end,
            desc = "Diff against revision",
        },
        { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
    },
}
