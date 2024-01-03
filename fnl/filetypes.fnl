(module filetypes)

(defn init []
  (vim.filetype.add
    {:filename
     {"compose.yaml" "dockercompose"
      ".dockerignore" "dockerignore"}})
  (vim.filetype.add
    {:extension 
     {:shellscript "shellscript"}})
  (vim.filetype.add
    {:extension 
     {:shellscript "dockerai"}}))
