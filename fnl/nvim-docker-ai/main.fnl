(module nvim-docker-ai.main
  {require {dockerai dockerai
            filetypes filetypes
            nano-copilot nano-copilot
            core aniseed.core}})

(defn init []
  (core.println "initialize docker ai")
  (filetypes.init))
