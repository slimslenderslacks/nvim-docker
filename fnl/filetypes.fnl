(module filetypes)

(vim.filetype.add
  {:filename
   {"compose.yaml" "dockercompose"
    ".dockerignore" "dockerignore"}
   :extension 
   {:shellscript "shellscript"}})

