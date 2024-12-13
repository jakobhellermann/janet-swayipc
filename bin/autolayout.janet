(import swayipc)

(import spork/json)
(import spork/randgen)
(use sh)

(def verbose false)


## utils

(defn project-recursive "Takes the struct `val` and recursively filters its keys to only the specified `items`" [val items]
  (cond
    (table? val)
    (reduce (fn [acc item] (put acc item (project-recursive (val item) items))) @{} items)
    (array? val)
    (map |(project-recursive $ items) val)
    val))

(defn locate-recursive [obj children-key id-key id]
  (def nodes (obj children-key))
  (if (compare= (obj id-key) id) [obj]
    (match nodes
      nil nil
      nodes (label result
              (each node nodes
                (def r (locate-recursive node children-key id-key id))
                (if-not (nil? r)
                  (return result [obj ;r])))))))

(defn second-last [ind] (ind (- (length ind) 2)))

(defn second-last [ind] (ind (- (length ind) 2)))

## utils end

(defn send [msg]
  (if verbose
    ($ notify-send -t 1000 ,msg))
  (print msg))


(defn workspace-layout [conn]
  (def tree (swayipc/send :get_tree conn))
  (project-recursive tree ["name" "type" "id" "orientation" "nodes" "focused" "layout"]))


(defn node-name [node]
  (cond
    (= (node "type") "workspace") (string/format "%s-%s" (node "name") (node "layout"))
    (= (node "name") :null) (node "layout")
    (node "name")))

(defn auto-layout [conn id]
  (def workspaces (workspace-layout conn))
  (def path (locate-recursive workspaces "nodes" "id" id))

  (when (nil? path)
    (print "Focused node not found in workspace?")
    (break))

  (def c0 (last path))
  (def c1 (second-last path))

  (print (string "Focus " ;(interpose " " (map |(string/format "'%s'" (node-name $0)) path))))

  (when (and
          (= (c1 "orientation") "horizontal")
          (>= (length (c1 "nodes")) 2)
          (<= (length path) 4))
    (send "autolayout vertical")
    (swayipc/command "split vertical" conn))

  (when (and
          (compare= (c1 "orientation") "vertical")
          (compare= (length (c1 "nodes")) 2)
          (compare= ((last (c1 "nodes")) "id") (c0 "id")))
    (send "autolayout horizontal")
    (swayipc/command "split horizontal" conn)))

(defn main [& args]
  (def conn (swayipc/connect))
  (print "Listening for focus events")

  (def result (swayipc/subscribe [:window] conn))

  (while true
    (do (def event (swayipc/recv conn))

      (match (event "change")
        "focus" (do
                  (def id ((event "container") "id"))
                  (auto-layout conn id))))))
