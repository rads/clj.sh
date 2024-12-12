(ns clj.sh
  (:require [babashka.cli :as cli]
            [clojure.java.io :as io]
            [clojure.set :as set]
            [clojure.string :as str]
            [clojure.tools.logging :as log]
            [muuntaja.core :as m]
            [nrepl.cmdline :as nrepl]
            [reitit.ring :as reitit-ring]
            [reitit.ring.middleware.muuntaja :as muuntaja]
            [ring.adapter.jetty9 :as jetty]
            [ring.util.response :as response]))

(defn- wrap-exceptions [handler params]
  (if (:show-errors params)
    ((requiring-resolve 'prone.middleware/wrap-exceptions)
     handler
     {:app-namespaces [(ns-name *ns*)]})
    (fn [req]
      (try
        (handler req)
        (catch Throwable e
          (log/error e)
          (response/status 500))))))

(def generate-script
  (let [[prefix suffix] (->> (slurp (io/resource "run.sh"))
                             str/split-lines
                             (split-with #(not (str/includes? % "# START GENERATED CODE"))))]
    (fn [{:keys [bbin-args]}]
      (let [lines (concat prefix
                          ["  # START GENERATED CODE"
                           "  BBIN_ARGS=$(cat <<EOF"
                           bbin-args
                           "EOF"
                           ")"
                           "  # END GENERATED CODE"]
                          (drop 3 suffix))]
        (str/join "\n" lines)))))

(defn- symbol-str? [s]
  (boolean (re-matches #"(?i)^[a-z][a-z0-9_.\-]+(/[a-z0-9_.\-]+)?$" s)))

(def index-src (slurp (io/resource "index.sh")))
(def invalid-src (slurp (io/resource "invalid.sh")))

(defn run-handler [{:keys [path-params] :as _req}]
  (let [{:keys [path]} path-params]
    (cond
      (str/blank? path) (response/response index-src)
      (not (symbol-str? path)) (response/not-found invalid-src)
      :else (response/response
              (generate-script {:bbin-args (format "install %s --edn" path)})))))

(def app-routes
  [["/*path" {:get run-handler}]])

(defn ->app-handler []
  (reitit-ring/ring-handler
    (reitit-ring/router
      app-routes
      {:data {:muuntaja m/instance
              :middleware [muuntaja/format-middleware]}})
    (reitit-ring/routes
      (reitit-ring/redirect-trailing-slash-handler {:method :strip})
      (reitit-ring/create-default-handler))))

(defn- start-repl! [params]
  (let [nrepl-cli-opts (-> (select-keys params [:repl-port])
                           (set/rename-keys {:repl-port :port}))
        repl-opts (nrepl/server-opts nrepl-cli-opts)
        repl-server (nrepl/start-server repl-opts)]
    (nrepl/ack-server repl-server repl-opts)
    (nrepl/save-port-file repl-server repl-opts)
    (log/info (nrepl/server-started-message repl-server repl-opts))))

(defn- start-jetty!
  [{:keys [reload port]
    :or {port 3000}
    :as params}]
  (let [handler (-> (if reload
                      (reitit-ring/reloading-ring-handler ->app-handler)
                      (->app-handler))
                    (wrap-exceptions params))]
    (jetty/run-jetty handler {:port port, :join? false})))

(defonce current-app (atom nil))

(defn start-app! [params]
  (reset! current-app {:server (start-jetty! params)}))

(defn stop-app! []
  (when-let [{:keys [server]} @current-app]
    (jetty/stop-server server)))

(defn start! [params]
  (start-repl! params)
  (start-app! params))

(defonce cli-args *command-line-args*)

(defn restart! []
  (stop-app!)
  (start-app! (cli/parse-opts cli-args)))

(defn after-ns-reload []
  (restart!))

(defn -main [& _]
  (start! (cli/parse-opts cli-args)))

(comment
  (after-ns-reload))
