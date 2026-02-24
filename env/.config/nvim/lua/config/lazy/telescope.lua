return {
    "nvim-telescope/telescope.nvim",

    dependencies = {
        "nvim-lua/plenary.nvim"
    },

    config = function()
        require('telescope').setup({})

        local builtin = require('telescope.builtin')
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        -- Custom test finder
        local function find_tests()
            local make_entry = require("telescope.make_entry")
            pickers.new({}, {
                prompt_title = "Find Tests",
                finder = finders.new_oneshot_job({
                    "rg", "--vimgrep", "def test_",
                    "-g", "test_*.py",
                    "-g", "*_test.py"
                }, {
                    entry_maker = make_entry.gen_from_vimgrep({})
                }),
                sorter = conf.generic_sorter({}),
                previewer = conf.grep_previewer({}),
                attach_mappings = function(prompt_bufnr, map)
                    -- <CR> jumps to test
                    actions.select_default:replace(function()
                        local entry = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        vim.cmd("edit " .. entry.filename)
                        vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
                    end)
                    -- <C-r> runs test
                    map("i", "<C-r>", function()
                        local entry = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        vim.cmd("edit " .. entry.filename)
                        vim.api.nvim_win_set_cursor(0, { entry.lnum, 0 })
                        vim.cmd("TestNearest")
                    end)
                    return true
                end,
            }):find()
        end

        vim.keymap.set('n', '<leader>pt', find_tests, { desc = "Find tests" })
        vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
        vim.keymap.set('n', '<C-p>', builtin.git_files, {})
        vim.keymap.set('n', '<leader>pws', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>pWs', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end)
        vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
        vim.keymap.set('n', '<leader>gs', builtin.git_status, {})
    end
}

