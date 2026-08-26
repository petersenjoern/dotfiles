return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("nvim-tree").setup({
            git = {
                ignore = false,
            },
            filesystem_watchers = {
                ignore_dirs = {
                    ".worktrees",
                },
            },
            view = {
                width = 35,
                -- otherwise opening a file equalizes all windows and the tree snaps back
                preserve_window_proportions = true,
            },
            on_attach = function(bufnr)
                local api = require("nvim-tree.api")
                api.config.mappings.default_on_attach(bufnr)

                local function opts(desc)
                    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true }
                end

                vim.keymap.set("n", "<C-Right>", function() api.tree.resize({ relative = 5 }) end, opts("Widen"))
                vim.keymap.set("n", "<C-Left>", function() api.tree.resize({ relative = -5 }) end, opts("Narrow"))
                vim.keymap.set("n", "<leader>r", function() api.tree.resize() end, opts("Reset width"))
            end,
        })
        vim.keymap.set("n", "<C-S-e>", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })
        vim.keymap.set("n", "<leader>fe", ":NvimTreeFindFile<CR>", { desc = "Reveal file in tree" })
    end
}
