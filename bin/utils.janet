(import spork/json)

(defn get! [val key]
  (assert (in val key) (string key " not found in " ;(interpose ", " (keys val))))
  (get val key))

(defmacro def-env [name env]
  ~(upscope (def ,name (get (os/environ) ,env))
     (assert ,name (string/format "%s env var not defined" ,env))))

(defn second-last [ind] (ind (- (length ind) 2)))

(defn printjson [val] (print (json/encode val "  ")))

(defn project-recursive "Takes the struct `val` and recursively filters its keys to only the specified `items`" [val items]
  (cond
    (table? val)
    (reduce (fn [acc item] (put acc item (project-recursive (val item) items))) @{} items)
    (array? val)
    (map |(project-recursive $ items) val)
    val))


(defn transform "Takes the struct `val`, and recursively applies `f` to the key `k`" [val k f]
  (cond
    (table? val)
    (reduce (fn [acc key]
              (def mapped (if (compare= key k)
                            (f (val key))
                            (val key)))
              (put acc key (transform mapped k f))) @{} (keys val))
    (array? val)
    (map |(transform $ k f) val)
    val))

(defn group-by-single "like group-by but doesn't insert array" [f ind]
  (reduce (fn [acc item] (put acc (f item) item)) @{} ind))

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
