return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("nvim-tree").setup()
        vim.keymap.set("n", "<C-S-e>", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })
        vim.keymap.set("n", "<leader>fe", ":NvimTreeFindFile<CR>", { desc = "Reveal file in tree" })
    end
}
