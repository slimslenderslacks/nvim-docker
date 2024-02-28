## neovim-docker-ai

## Installation

### Lazy

If you're using [lazy](https://github.com/folke/lazy.nvim), then add `slimslenderslacks/nvim-docker-ai` to your setup.  You'll
also need `nvim-cmp`.

```lua
-- somewhere you probably have a good lsp centric keymap defined.  Here's one that I like.
function bufKeymap()
  vim.api.buf_set_keyamp(bufnr, "n", "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "v", "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "n", "gd",         "<cmd>lua vim.lsp.buf.definition()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "n", "K",          "<cmd>lua vim.lsp.buf.hover()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "n", "ld",         "<cmd>lua vim.lsp.buf.declaration()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "n", "lt",         "<cmd>lua vim.lsp.buf.definition()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "n", "ln",         "<cmd>lua vim.lsp.buf.rename()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "n", "lf",         "<cmd>lua vim.lsp.buf.format()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "v", "lf",         "<cmd>lua vim.lsp.buf.format()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "n", "<leader>le", "<cmd>lua vim.diagnostic.open_float()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "n", "<leader>ll", "<cmd>lua vim.diagnostic.setlocllist()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "n", "<leader>lj", "<cmd>lua vim.diagnostic.goto_next()<CR>", {noremap = true})     
  vim.api.buf_set_keyamp(bufnr, "n", "<leader>lk", "<cmd>lua vim.diagnostic.goto_prev()<CR>", {noremap = true})     

  -- only if you're using telescope
  vim.api.buf_set_keyamp(bufnr, "n", "<leader>lw", "<cmd>lua require('telescope.builtin').diagnostics()<CR>", {noremap = true})     
end

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

This does not rely on [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) to manage the LSP, but it does require a recent version of neovim.  I current use `v0.10.0-dev-80f75d0` but anything greater than 0.9.0 should work.  
In my opinion, nvim-lspconfig is becoming less and less useful as the core `lsp` support in neovim has improved.  

### Using Ollama

If you have [Ollama installed](https://ollama.ai/) installed and running, Docker AI
will use it.  Docker AI will not start Ollama - if you want to use it, you'll have to start 
it separately

### Pulling the lsp container

The neovim-docker-ai plugin wraps a new LSP that we are currently distributing using a Docker Image.  It will not currently be pulled automatically.

```sh
docker pull docker/lsp:staging
```

### Using Docker AI

* the LSP will attach itself to the following buffers
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
# docker:command=build

make
```

