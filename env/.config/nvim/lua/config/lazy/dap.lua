return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "williamboman/mason.nvim",
        "jay-babu/mason-nvim-dap.nvim",
    },

    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        -- Mason DAP setup - auto-install debug adapters
        require("mason-nvim-dap").setup({
            ensure_installed = {
                "python",    -- debugpy
                "delve",     -- Go
                "codelldb",  -- Rust/C/C++
            },
            automatic_installation = true,
            handlers = {},
        })

        -- DAP UI setup
        dapui.setup({
            icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
            mappings = {
                expand = { "<CR>", "<2-LeftMouse>" },
                open = "o",
                remove = "d",
                edit = "e",
                repl = "r",
                toggle = "t",
            },
            layouts = {
                {
                    elements = {
                        { id = "scopes", size = 0.25 },
                        { id = "breakpoints", size = 0.25 },
                        { id = "stacks", size = 0.25 },
                        { id = "watches", size = 0.25 },
                    },
                    position = "left",
                    size = 40,
                },
                {
                    elements = {
                        { id = "repl", size = 0.5 },
                        { id = "console", size = 0.5 },
                    },
                    position = "bottom",
                    size = 10,
                },
            },
        })

        -- Virtual text for variable values
        require("nvim-dap-virtual-text").setup({
            enabled = true,
            enabled_commands = true,
            highlight_changed_variables = true,
            highlight_new_as_changed = false,
            show_stop_reason = true,
            commented = false,
        })

        -- Auto open/close DAP UI
        dap.listeners.before.attach.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
            dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            dapui.close()
        end

        -- Breakpoint signs
        vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
        vim.fn.sign_define("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
        vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })
        vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" })
        vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DapBreakpointRejected", linehl = "", numhl = "" })

        -- Highlight groups for signs
        vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
        vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#f9a825" })
        vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })
        vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379", bg = "#31353f" })
        vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#656565" })

        ---------------------------------------------------------------------
        -- Python (debugpy)
        ---------------------------------------------------------------------
        dap.adapters.python = function(cb, config)
            if config.request == "attach" then
                local port = (config.connect or config).port
                local host = (config.connect or config).host or "127.0.0.1"
                cb({
                    type = "server",
                    port = assert(port, "`connect.port` is required for attach"),
                    host = host,
                    options = { source_filetype = "python" },
                })
            else
                cb({
                    type = "executable",
                    command = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
                    args = { "-m", "debugpy.adapter" },
                    options = { source_filetype = "python" },
                })
            end
        end

        -- Helper: Load environment variables from .env file
        local function load_env_file(env_path)
            local env = {}
            local file = io.open(env_path, "r")
            if file then
                for line in file:lines() do
                    -- Skip comments and empty lines
                    if line:match("^%s*[^#]") then
                        local key, value = line:match("^%s*([^=]+)%s*=%s*(.*)%s*$")
                        if key and value then
                            -- Remove quotes if present
                            value = value:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
                            env[key] = value
                        end
                    end
                end
                file:close()
            end
            return env
        end

        -- Helper: Get python path from virtualenv or system
        local function get_python_path()
            local venv = os.getenv("VIRTUAL_ENV")
            if venv then
                return venv .. "/bin/python"
            end
            return "/usr/bin/python3"
        end

        dap.configurations.python = {
            {
                type = "python",
                request = "launch",
                name = "Launch file",
                program = "${file}",
                pythonPath = get_python_path,
            },
            {
                type = "python",
                request = "launch",
                name = "Launch file with arguments",
                program = "${file}",
                args = function()
                    local args_string = vim.fn.input("Arguments: ")
                    return vim.split(args_string, " +")
                end,
                pythonPath = get_python_path,
            },
            {
                type = "python",
                request = "attach",
                name = "Attach remote",
                connect = function()
                    local host = vim.fn.input("Host [127.0.0.1]: ")
                    host = host ~= "" and host or "127.0.0.1"
                    local port = tonumber(vim.fn.input("Port [5678]: ")) or 5678
                    return { host = host, port = port }
                end,
            },
        }

        ---------------------------------------------------------------------
        -- Go (delve)
        ---------------------------------------------------------------------
        dap.adapters.delve = {
            type = "server",
            port = "${port}",
            executable = {
                command = vim.fn.stdpath("data") .. "/mason/packages/delve/dlv",
                args = { "dap", "-l", "127.0.0.1:${port}" },
            },
        }

        dap.configurations.go = {
            {
                type = "delve",
                name = "Debug",
                request = "launch",
                program = "${file}",
            },
            {
                type = "delve",
                name = "Debug Package",
                request = "launch",
                program = "${fileDirname}",
            },
            {
                type = "delve",
                name = "Debug test",
                request = "launch",
                mode = "test",
                program = "${file}",
            },
            {
                type = "delve",
                name = "Debug test (go.mod)",
                request = "launch",
                mode = "test",
                program = "./${relativeFileDirname}",
            },
            {
                type = "delve",
                name = "Attach remote",
                mode = "remote",
                request = "attach",
            },
        }

        ---------------------------------------------------------------------
        -- Rust / C / C++ (codelldb)
        ---------------------------------------------------------------------
        dap.adapters.codelldb = {
            type = "server",
            port = "${port}",
            executable = {
                command = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb",
                args = { "--port", "${port}" },
            },
        }

        dap.configurations.rust = {
            {
                name = "Launch",
                type = "codelldb",
                request = "launch",
                program = function()
                    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
                end,
                cwd = "${workspaceFolder}",
                stopOnEntry = false,
            },
        }

        dap.configurations.c = dap.configurations.rust
        dap.configurations.cpp = dap.configurations.rust

        ---------------------------------------------------------------------
        -- Keymaps (leader + d for debug)
        ---------------------------------------------------------------------
        -- Toggle breakpoint | Trigger: SPACE + d + b
        vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
        -- Set conditional breakpoint | Trigger: SPACE + d + B
        vim.keymap.set("n", "<leader>dB", function()
            dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end, { desc = "Set conditional breakpoint" })
        -- Set log point | Trigger: SPACE + d + l
        vim.keymap.set("n", "<leader>dl", function()
            dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
        end, { desc = "Set log point" })

        -- Start/Continue | Trigger: SPACE + d + c
        vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
        -- Step over | Trigger: SPACE + d + o
        vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step over" })
        -- Step into | Trigger: SPACE + d + i
        vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
        -- Step out | Trigger: SPACE + d + O
        vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Step out" })

        -- Run to cursor | Trigger: SPACE + d + r
        vim.keymap.set("n", "<leader>dr", dap.run_to_cursor, { desc = "Run to cursor" })
        -- Terminate | Trigger: SPACE + d + x
        vim.keymap.set("n", "<leader>dx", dap.terminate, { desc = "Terminate" })
        -- Restart | Trigger: SPACE + d + R
        vim.keymap.set("n", "<leader>dR", dap.restart, { desc = "Restart" })

        -- Toggle DAP UI | Trigger: SPACE + d + u
        vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
        -- Eval expression under cursor | Trigger: SPACE + d + e
        vim.keymap.set({ "n", "v" }, "<leader>de", dapui.eval, { desc = "Eval" })
        -- Open REPL | Trigger: SPACE + d + p
        vim.keymap.set("n", "<leader>dp", dap.repl.open, { desc = "Open REPL" })

        -- List breakpoints | Trigger: SPACE + d + L
        vim.keymap.set("n", "<leader>dL", function()
            dap.list_breakpoints()
            vim.cmd("copen")
        end, { desc = "List breakpoints" })
        -- Clear all breakpoints | Trigger: SPACE + d + C
        vim.keymap.set("n", "<leader>dC", dap.clear_breakpoints, { desc = "Clear all breakpoints" })

        ---------------------------------------------------------------------
        -- Project-local DAP configs (.nvim/dap.lua)
        ---------------------------------------------------------------------
        local project_dap = vim.fn.getcwd() .. "/.nvim/dap.lua"
        local stat = vim.uv.fs_stat(project_dap)
        if stat then
            local ok, result = pcall(dofile, project_dap)
            if ok then
                local ctx = {
                    load_env_file = load_env_file,
                    get_python_path = get_python_path,
                }
                local configs = type(result) == "function" and result(ctx) or result
                for lang, confs in pairs(configs or {}) do
                    dap.configurations[lang] = dap.configurations[lang] or {}
                    for _, conf in ipairs(confs) do
                        table.insert(dap.configurations[lang], conf)
                    end
                end
            else
                vim.notify("Failed to load .nvim/dap.lua: " .. result, vim.log.levels.WARN)
            end
        end
    end,
}
