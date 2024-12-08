(import ../src/swayipc)
(use ./utils)

(import spork/json)
(import spork/randgen)
(use sh)

(def verbose false)

(defn send [msg]
  (if verbose
    ($ notify-send -t 1000 ,msg))
  (print msg))


(defn workspace-layout [conn]
  (def tree (swayipc/send conn :get_tree))
  (project-recursive tree ["name" "type" "id" "orientation" "nodes" "focused" "layout"]))


(defn auto-layout [conn id]
  (def workspaces (workspace-layout conn))
  (def path (locate-recursive workspaces "nodes" "id" id))

  (def c0 (last path))
  (def c1 (second-last path))

  (print (string "Focus " ;(interpose " " (map |(string/format "'%s'" ($0 "name")) path))))

  (if (and
        (compare= (c1 "orientation") "horizontal")
        (compare= (length (c1 "nodes")) 2)
        (compare= ((last (c1 "nodes")) "id") (c0 "id"))
        (compare<= (length path) 4))

    (do
      (send "autolayout vertical")
      (swayipc/command conn "split vertical")))

  (if (and
        (compare= (c1 "orientation") "vertical")
        (compare= (length (c1 "nodes")) 2)
        (compare= ((last (c1 "nodes")) "id") (c0 "id")))
    (do
      (send "autolayout horizontal")
      (swayipc/command conn "split horizontal"))))

(defn main [& args]
  (def conn (swayipc/connect))
  (print "Listening for focus events")

  (def result (swayipc/subscribe conn [:window]))

  (while true
    (do (def event (swayipc/recv conn))

      (match (event "change")
        "focus" (do
                  (def id ((event "container") "id"))
                  (auto-layout conn id))))))
