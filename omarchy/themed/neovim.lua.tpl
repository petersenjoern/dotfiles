-- Overrides Omarchy's built-in default/themed/neovim.lua.tpl. User templates in
-- ~/.config/omarchy/themed are rendered first, and a matching output filename
-- skips the built-in one.
--
-- Same aether.nvim spec as upstream, minus the `LazyVim/LazyVim` entry: this
-- config is plain lazy.nvim, so that entry would install LazyVim as a plugin.
-- The colorscheme is applied by ColorMyPencils() instead.
return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "{{ background }}",
        dark_bg = "{{ dark_background }}",
        darker_bg = "{{ darker_background }}",
        lighter_bg = "{{ lighter_background }}",

        fg = "{{ foreground }}",
        dark_fg = "{{ dark_foreground }}",
        light_fg = "{{ light_foreground }}",
        bright_fg = "{{ bright_foreground }}",
        muted = "{{ muted }}",

        red = "{{ red }}",
        yellow = "{{ yellow }}",
        orange = "{{ orange }}",
        green = "{{ green }}",
        cyan = "{{ cyan }}",
        blue = "{{ blue }}",
        magenta = "{{ magenta }}",
        brown = "{{ brown }}",

        bright_red = "{{ bright_red }}",
        bright_yellow = "{{ bright_yellow }}",
        bright_green = "{{ bright_green }}",
        bright_cyan = "{{ bright_cyan }}",
        bright_blue = "{{ bright_blue }}",
        bright_magenta = "{{ bright_magenta }}",

        accent = "{{ accent }}",
        cursor = "{{ bright_foreground }}",
        foreground = "{{ foreground }}",
        background = "{{ background }}",
        selection = "{{ selection }}",
        selection_foreground = "{{ selection_foreground }}",
        selection_background = "{{ selection_background }}",
      },
    },
  },
}
