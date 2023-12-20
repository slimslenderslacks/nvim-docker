## neovim-docker-ai

## Installation

### Packer

If you're using [packer](https://github.com/wbthomason/packer.nvim), then add an additional call to `use`
in your `init.lua` file.

```lua
require('packer').startup(
  function(use)
    use {'slimslenderslacks/nvim-docker-ai',
         requires = {'slimslenderslacks/nvim-lsp',
                     'Olical/aniseed'
                     'nvim-lua/plenary.vim'}}
  end)
```

### Using Ollama

Make sure you have [Ollama installed](https://ollama.ai/) and running.  
This is a very simple plugin.  It won't start Ollama for you.

Highlight some text in one of your buffers, and then use the keybinding `<leader>ai`. 
A question will show up in the command prompt.  Type a question pertaining to the
code you've selected.  A floating window will contain the output streamed from 
Ollama.

### Using Docker AI


