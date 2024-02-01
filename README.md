## neovim-docker-ai

## Installation

### Lazy

If you're using [lazy](https://github.com/folke/lazy.nvim), then add an additional call to `use`
in your `init.lua` file.

```lua
require('lazy').setup(
  { 
    {
      'slimslenderslacks/nvim-docker-ai',
      lazy=false,
      dependencies = {
        'Olical/aniseed',
        'nvim-lua/plenary.nvim',
        'hrsh7th/nvim-cmp'
      },
      config = function()
        
      end,
    },
    {
      'hrsh7th/nvim-cmp',
      dependencies = {'hrsh7th/cmp-buffer',
                      'hrsh7th/cmp-nvim-lsp', }
    },
  }
)
```

This does not rely on [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) to manage the LSP, but it does require a recent version of neovim.  I current use `v0.10.0-dev-80f75d0` but anything greater than 0.9.0 should work.  
In my opinion, nvim-lspconfig is becoming less and less useful as the core `lsp` support in neovim has improved.  

### Using Ollama

If you have [Ollama installed](https://ollama.ai/) installed and running, Docker AI
will use it.  Docker AI will not start Ollama - if you want to use it, you'll have to start 
it separately

### Using Docker AI

* Docker AI ships has an LSP that will attach itself to the following buffers
    * dockerfile
    * dockerignore (new filetype registered by this plugin)
    * dockercompose (new filetype registered by this plugin)
    * dockerbake (new filetype registered by this plugin)
    * markdown
* you may have several LSPs registered for the markdown filetype. Docker AI 
  adds Docker runbook features to the markdown filetype
* Highlight some text in one of your buffers, and then use the keybinding `<leader>ai`(not currently
  support a custom binding for this). 
  A question will show up in the command prompt.  Type a question pertaining to the
  code you've selected.  A floating window will contain the output streamed from 
  Ollama.

### Building

```sh
make
```
