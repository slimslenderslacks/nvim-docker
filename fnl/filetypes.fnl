(module filetypes)

(defn init []
  (vim.filetype.add
    {:pattern 
     {".*compose.y.?ml" "dockercompose.yaml"}
     :filename
     {".dockerignore" "dockerignore"}})
  (vim.filetype.add
    {:extension 
     {:shellscript "shellscript"}})
  ;(vim.filetype.add
    ;{:extension 
     ;{:shellscript "dockerai"}})
  )
