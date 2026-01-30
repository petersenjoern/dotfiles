return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local function harpoon_index()
            local ok, harpoon = pcall(require, "harpoon")
            if not ok then
                return ""
            end
            local list = harpoon:list()
            local current_file = vim.fn.expand("%:p:.")

            for i, item in ipairs(list.items) do
                if item.value == current_file then
                    return "[" .. i .. "]"
                end
            end
            return ""
        end

        require("lualine").setup({
            options = {
                theme = "auto",
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                globalstatus = true,
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "diagnostics" },
                lualine_y = { harpoon_index },
                lualine_z = { "filetype" },
            },
        })
    end,
}
