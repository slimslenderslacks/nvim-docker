# nvim-copilot

## What is this

This project implements a very simple copilot-like experience in a terminal-based editor (neovim)
using only local LLMs.  We are exploring 2 things here.

* can we create copilot-like experiences using only local LLMs?
* how easily can we add llm prompts to a terminal-based editor like neovim?

Here's an example of our simple copilot in action.  This is using llama3 running in Ollama.

![copilot](./assets/ask.gif)

## How do you use this

This is distributed as a standard neovim plugin module.  After installing, highlight some text in the buffer 
and type `<leader>ai` to ask the LLM a question about the highlighted text.

## Installation

### Installing with Lazy

If you're using [lazy](https://github.com/folke/lazy.nvim), then add `docker/labs-nvim-copilot` to your setup.

```lua
require('lazy').setup(
  { 
    {
      'docker/labs-nvim-copilot',
      lazy=false,
      dependencies = {
        'Olical/aniseed',
        'nvim-lua/plenary.nvim',
        'hrsh7th/nvim-cmp'
      },
      config = function(plugin, opts)
        require("dockerai").setup(
          {attach = bufKeymap})
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

### Using Ollama

If you have [Ollama installed](https://ollama.ai/) installed and running, Docker AI
will use it.  Docker AI will not start Ollama - if you want to use it, you'll have to start 
it separately

### Commands

* **:DockerDebug** - download internal representations of project context for debug

### Building

```sh
# docker:command=build

make
```

