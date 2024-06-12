(module nvim-docker.main
  {require {commands docker.setup
            filetypes filetypes
            nano-copilot nano-copilot
            core aniseed.core
            lsps lsps
            runbooks runbooks}})

(defn init []
  (filetypes.init))

(defn after [])
