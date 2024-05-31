(module dockerai
  {autoload {nvim aniseed.nvim
             core aniseed.core
             string aniseed.string
             util slim.nvim}
   require {lsps lsps}})

(defn start-lsps []
  "start both docker_ai and docker_lsp services"
  (let [root-dir ;; TODO (util.git-root)
          (vim.fn.getcwd)
        extra-handlers {"docker/jwt" lsps.jwt-handler
                        "$terminal/run" lsps.terminal-run-handler
                        "$bind/run" lsps.terminal-bind-handler}]
    (lsps.start root-dir extra-handlers)))

(defn stop []
  (let [docker-lsp (. (lsps.get-client-by-name "docker_lsp") :id)]
    (when docker-lsp (vim.lsp.stop_client docker-lsp  false))))

(defn lsp-debug [_]
  (vim.ui.select
      ["documents"
       "project-context"
       "tracking-data"
       "login"
       "alpine-packages"
       "repositories"
       "client-settings"] 
      {:prompt "Choose Type of Data:"
       :format (fn [item] (item:gsub "_" " "))}
      (fn [selected _]
        (let [client (lsps.get-client-by-name "docker_lsp")]
          (client.request_sync "docker/debug" {:type selected})))))

(defn setup [{:attach cb}]
  (lsps.setup cb))

(defn tail_server_info []
  (let [clients (vim.lsp.get_active_clients)]
    (each [n client (pairs clients)]
      (if (= client.name "docker_lsp")
        (let [result (client.request_sync "docker/serverInfo/raw" {} 5000)]
          (print result.result.port result.result.log-path result.result.team-id)
          (nvim.command  (core.str "vs | :term bash -c \"tail -f " result.result.log-path "\"")))))))

(defn set_scout_workspace [args]
  (let [clients (vim.lsp.get_active_clients)]
    (each [n client (pairs clients)]
      (if (= client.name "docker_lsp")
        (let [result (client.request_sync "docker/select-scout-workspace" args 5000)]
          (print result))))))

(defn show_scout_workspace [args]
  (let [clients (vim.lsp.get_active_clients)]
    (each [n client (pairs clients)]
      (if (= client.name "docker_lsp")
        (let [result (client.request_sync "docker/show-scout-workspace" args 5000)]
          (print result))))))

(defn docker_server_info [args]
  (let [clients (vim.lsp.get_active_clients)]
    (each [n client (pairs clients)]
      (if (= client.name "docker_lsp")
        (let [result (client.request_sync "docker/serverInfo/show" args 5000)]
          (core.println result))))))

(defn docker_login [args]
  (let [clients (vim.lsp.get_active_clients)]
    (each [n client (pairs clients)]
      (if (= client.name "docker_lsp")
        (let [logout-result (client.request_sync "docker/logout" args 5000)
              login-result (client.request_sync "docker/login" args 5000)]
          (core.println login-result))))))

(defn docker_logout [args]
  (let [clients (vim.lsp.get_active_clients)]
    (each [n client (pairs clients)]
      (if (= client.name "docker_lsp")
        (let [result (client.request_sync "docker/logout" args 5000)]
          (print result))))))

(nvim.create_user_command "DockerServerInfo" docker_server_info {:nargs "?"})
(nvim.create_user_command "DockerDebug" lsp-debug {:desc "Get some state from the Docker LSP"})
(nvim.create_user_command "DockerShowOrg" show_scout_workspace {:nargs "?"})
(nvim.create_user_command "DockerSetOrg" show_scout_workspace {:nargs "?"})
(nvim.create_user_command "DockerLogin" docker_login {:nargs "?"})

(comment
  (vim.api.nvim_create_user_command "DockerAIStart" start {:desc "Start the LSPs for Docker AI"})
  (vim.api.nvim_create_user_command "DockerAIStop" stop {:desc "Stop the LSPs for Docker AI"})
  (nvim.create_user_command "DockerLogout" docker_logout {:nargs "?"}))

