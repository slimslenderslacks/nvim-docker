(module filetypes)

(vim.filetype.add
  {:filename
   {"compose.yaml" "dockercompose"
    ".dockerignore" "dockerignore"}})

(vim.filetype.add
  {:extension 
   {:shellscript "shellscript"}})
