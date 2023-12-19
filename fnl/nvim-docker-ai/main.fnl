(module nvim-docker-ai.main
  {autoload {dockerai dockerai
             filetypes filetypes
             nano-copilot nano-copilot
             core aniseed.core}})

(defn init []
  (core.println "initialize docker ai"))
