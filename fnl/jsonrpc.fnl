(module jsonrpc
  {autoload {core aniseed.core
             str aniseed.string
             nvim aniseed.nvim}})

(defn parse-message [s]
  (case-try (pcall (fn [] (string.find s "(%S+): (%d+)\r\n\r\n(.*)")))
            (true x y _ content-length json)  
            (string.sub json 1 (tonumber content-length))
            json-string (pcall (fn [] (vim.json.decode json-string)))
            (true obj) obj 
            (catch
              (false err) {:error err :data s}
              _ {:error "unknown" :data s})))

(defn message-splitter [agg s n]
  (case (string.find s "Content" n)
    (start end) (message-splitter (core.concat agg [start]) s end)
    _ agg))

(defn message-iterator [s]
  (local start-locations (message-splitter [] s 1))
  (var index 1)
  (fn []
    (let [start (. start-locations index)
          end (. start-locations (core.inc index))]
      (if 
        (and start end) (do 
                          (set index (core.inc index))
                          (string.sub s start (core.dec end)))
        start (do
                (set index (core.inc index))
                (string.sub s start))))))

(defn messages [data]
  (icollect [s (message-iterator data)] 
    (parse-message s))) 

(comment
  (message (core.slurp "hey.txt")))

