(module complaints
  {autoload {nvim aniseed.nvim
             core aniseed.core
             string aniseed.string
             util slim.nvim
             lsps lsps}})

(defn complain [{:path path 
                 :languageId language-id 
                 :startLine start-line 
                 :endLine end-line 
                 :edit edit 
                 :reason reason &as args}]
  (core.println complain args)
  (let [docker-lsp (lsps.get-client-by-name "docker_lsp")
        params {:uri {:external (.. "file://" path)} 
                :message reason 
                :range 
                {:start 
                 {:line (core.dec start-line)
                  :character 0} 
                 :end 
                 {:line (if end-line (- end-line 1) (- start-line 1))
                  :character -1}} 
                :edit edit}]
    (let [response (docker-lsp.request_sync "docker/complain" params 10000)]
      (print "docker/complain response")
      (print response))))


