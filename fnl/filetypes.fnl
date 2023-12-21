(module filetypes)

(vim.filetype.add
  {:extension 
   {:shellscript "shellscript"}
   :filename
   {"compose.yaml" "dockercompose"
    ".dockerignore" "dockerignore"}
   :pattern
   {"*.shellscript" "shellscript"}})

