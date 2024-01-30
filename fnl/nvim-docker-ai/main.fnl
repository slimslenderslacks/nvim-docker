(module nvim-docker-ai.main
  {require {dockerai dockerai
            filetypes filetypes
            nano-copilot nano-copilot
            core aniseed.core
            lsps lsps}})

(defn init []
  (filetypes.init))

(defn after [])
