(module jsonrpc
  {autoload {core aniseed.core
             str aniseed.string
             nvim aniseed.nvim}})

(defn parse-message [s]
  ""
  (case-try (pcall (fn [] (string.find s "(%S+): (%d+)\r\n\r\n(.*)")))
            ;; found an entire jsonrpc message
            (true x y _ content-length json)
            (string.sub json 1 (tonumber content-length))
            ;; this should be a valid json string
            json-string (pcall (fn [] (vim.json.decode json-string)))
            (true obj) obj
            (catch
              (false err) {:error (string.format "parse-message(%s)" err) :data s}
              _ {:error "parse-message(unknown)" :data s})))

(defn message-splitter [agg s n]
  (case (string.find s "Content%-Length" n)
    (start end) (message-splitter (core.concat agg [start]) s end)
    _ agg))

(defn message-iterator [s]
  "iterator for jsonrpc messages which start with Content and continue until the next Content"
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
  "args
     data - string message arriving jsonrpc server
   returns collection of json rpc messages"
  (icollect [s (message-iterator data)]
    (parse-message s)))

(comment
  (message (core.slurp "hey.txt")))

