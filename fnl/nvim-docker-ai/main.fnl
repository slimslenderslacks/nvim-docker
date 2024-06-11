(module nvim-docker-ai.main
  {require {commands commands
            filetypes filetypes
            nano-copilot nano-copilot
            core aniseed.core
            lsps lsps
            runbooks runbooks}})

(defn init []
  (filetypes.init))

(defn after [])
