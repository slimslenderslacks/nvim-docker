(module nvim-docker.main
  {require {commands docker.setup
            filetypes filetypes
            nano-copilot nano-copilot
            core aniseed.core
            lsps lsps
            runbooks runbooks
            prompt-runner prompts.runner}})

(defn init []
  (filetypes.init))

(defn after [])
