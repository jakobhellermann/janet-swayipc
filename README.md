# janet-swayipc

A [janet](https://janet-lang.org/) library for controlling [sway](https://github.com/swaywm/sway) throught its [IPC interface](https://man.archlinux.org/man/sway-ipc.7.en)

## Example usage


```janet
(import swayipc)

(defn main [&]
  (def conn (swayipc/connect))

  (pp (swayipc/send conn :get_version))
  (pp (swayipc/send conn :run_command "reload"))

  (pp (swayipc/subscribe conn [:window]))
  (while true (do
                (def event (swayipc/recv conn))
                (pp event))))

```

For further inspiration, [bin/autolayout.janet](./bin/autolayout.janet) contains a script that listens to window focus events,
and automatically executes `split vertical` or `split horizontal` based on rules that I personally prefer.