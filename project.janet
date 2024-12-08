(declare-project
  :name "swayipc"
  :description "sway-ipc bindings"
  :license "MIT"
  :dependencies ["https://github.com/janet-lang/spork.git" "https://github.com/andrewchambers/janet-sh"])


(declare-source :source ["src/swayipc.janet"])
# (declare-executable :name "autolayout" :entry "bin/autolayout.janet")

