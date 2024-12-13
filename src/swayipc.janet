(import spork/json)

(defn connect [&opt socket]
  (default socket ((os/environ) "SWAYSOCK"))
  (assert socket (string/format "SWAYSOCK env var not defined"))
  (net/connect :unix socket))

(def- swayipc-header (peg/compile
                       ~{:u32 (/ (<- 4) ,|(+ (blshift (get $ 0) 0)
                                             (blshift (get $ 1) 8)
                                             (blshift (get $ 2) 16)
                                             (blshift (get $ 3) 24)))
                         :main (* "i3-ipc" :u32 :u32)}))
(defn recv [&opt conn]
  (default conn (connect))
  (def header (ev/read conn 14))
  (def (len ty) (peg/match swayipc-header header))
  (def payload (ev/read conn len))
  (json/decode payload))


(def- types {:run_command 0
             :get_workspaces 1
             :subscribe 2
             :get_outputs 3
             :get_tree 4
             :get_marks 5
             :get_bar_config 6
             :get_version 7
             :get_binding_modes 8
             :get_config 9
             :send_tick 10
             :sync 11
             :get_binding_state 12
             :get_inputs 100
             :get_seats 101})


(defn- get! [val key]
  (assert (in val key) (string key " not found in " ;(interpose ", " (keys val))))
  (get val key))

(defn- swayipc-message [message-type payload]
  (def msg @"i3-ipc")
  (buffer/push-uint32 msg :native (length payload))
  (buffer/push-uint32 msg :native message-type)
  (buffer/push-string msg payload)
  (string msg))

(defn send ``Send a sway ipc message and receive the response
- 0 	RUN_COMMAND 	Runs the payload as sway commands
- 1 	GET_WORKSPACES 	Get the list of current workspaces
- 2 	SUBSCRIBE 	Subscribe the IPC connection to the events listed in the payload
- 3 	GET_OUTPUTS 	Get the list of current outputs
- 4 	GET_TREE 	Get the node layout tree
- 5 	GET_MARKS 	Get the names of all the marks currently set
- 6 	GET_BAR_CONFIG 	Get the specified bar config or a list of bar config names
- 7 	GET_VERSION 	Get the version of sway that owns the IPC socket
- 8 	GET_BINDING_MODES 	Get the list of binding mode names
- 9 	GET_CONFIG 	Returns the config that was last loaded
- 10 	SEND_TICK 	Sends a tick event with the specified payload
- 11 	SYNC 	Replies failure object for i3 compatibility
- 12 	GET_BINDING_STATE 	Request the current binding state, e.g. the currently active binding mode name.
- 100 	GET_INPUTS 	Get the list of input devices
- 101 	GET_SEATS 	Get the list of seats

EVENTS:
-	workspace  Sent whenever an event involving a workspace occurs such as initialization of a new workspace or a different workspace gains focus
-	output  Sent when outputs are updated
-	mode  Sent whenever the binding mode changes
-	window  Sent whenever an event involving a view occurs such as being reparented, focused, or closed
-	barconfig_update  Sent whenever a bar config changes
-	binding  Sent when a configured binding is executed
-	shutdown  Sent when the ipc shuts down because sway is exiting
-	tick  Sent when an ipc client sends a SEND_TICK message
-	bar_state_update  Send when the visibility of a bar should change due to a modifier
-	input  Sent when something related to input devices changes

  ``
  [message-type &opt conn payload]
  (default conn (connect))
  (default payload "")
  (def msg (swayipc-message (get! types message-type) payload))
  (:write conn msg)
  (recv conn))


(defn- do-subscribe [events &opt conn]
  (default conn (connect))
  (def result (send :subscribe conn (json/encode events)))
  (assert (compare= (get result "success") true))
  result)

(defn subscribe ``
Subscribe to events of the specified types, returning a fiber yielding events.

A list of possible events can be found here:
https://man.archlinux.org/man/sway-ipc.7.en#EVENTS
`` [events]
  (def conn (connect))
  (def result (do-subscribe [:window] conn))
  (assert (result "success"))
  (fiber/new |(forever
                (def event (recv conn))
                (yield event))))


(defn command [command &opt conn]
  (send :run_command conn command))

(defn get-tree [&opt conn]
  (send :get_tree conn))

(defn- yield-tree [obj children-key]
  (yield obj)
  (each child (obj children-key) (yield-tree child children-key)))

(defn focused-window [&opt conn]
  (def tree (get-tree conn))
  (->> (fiber/new |(yield-tree tree "nodes"))
       (find |($0 "focused"))))
