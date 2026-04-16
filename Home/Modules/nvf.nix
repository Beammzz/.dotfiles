{ ... }:
{
  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        viAlias = false;
        vimAlias = true;
        syntaxHighlighting = true;
        options = {
          tabstop = 2;
          shiftwidth = 2;
          expandtab = true;
        };

        lsp = {
          enable = true;
          formatOnSave = true;
        };

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };
        ui = {
          borders = {
            enable = true;
            globalStyle = "rounded";
            plugins.which-key.enable = true;
          };
          noice = {
            enable = true;
            setupOpts.presets.command_palette = true;
          };
        };
        visuals.indent-blankline.enable = true;
        statusline.lualine.enable = true;
        tabline.nvimBufferline.enable = true;
        dashboard.dashboard-nvim.enable = true;

        filetree.nvimTree = {
          enable = true;
          setupOpts = {
            view = {
              side = "left";
              width = 30;
            };
          };
        };
        autocomplete.nvim-cmp.enable = true;
        autopairs.nvim-autopairs.enable = true;
        telescope.enable = true;
        terminal.toggleterm.enable = true;
        git.enable = true;
        comments.comment-nvim.enable = true;

        assistant.copilot = {
          enable = true;
          cmp.enable = true;
        };

        languages = {
          nix = {
            enable = true;
            format.enable = true;
            format.type = ["alejandra"];
            lsp.enable = true;
            lsp.servers = ["nixd"];
          };
          yaml = {
            enable = true;
            lsp.enable = true;
            lsp.servers = ["yaml-language-server"];
          };
        };

        keymaps = [
          {
            key = "<C-p>";
            mode = "n";
            action = ":Telescope commands<CR>";
            desc = "VS Code-style Command Palette";
          }
          {
            key = "<C-z>";
            mode = ["n" "i" "v"];
            action = "<Cmd>undo<CR>";
            desc = "Undo";
          }
          {
            key = "<C-y>";
            mode = ["n" "i" "v"];
            action = "<Cmd>redo<CR>";
            desc = "Redo";
          }
          {
            key = "<C-s>";
            mode = ["n" "i" "v"];
            action = "<Cmd>w<CR>";
            desc = "Save File";
          }
          {
            key = "<C-x>";
            mode = ["n" "i" "v"];
            action = "<Cmd>wq<CR>";
            desc = "Save File";
          }
        ];

        luaConfigRC.nvim-tree-auto-close = ''
          vim.api.nvim_create_autocmd("BufEnter", {
            group = vim.api.nvim_create_augroup("NvimTreeClose", {clear = true}),
            pattern = "*",
            callback = function()
              local layout = vim.api.nvim_call_function("winlayout", {})
              if layout[1] == "leaf" and vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(layout[2]), "filetype") == "NvimTree" and layout[3] == nil then
                vim.cmd("confirm quit")
              end
            end
          })
        '';
      };
    };
  };
}