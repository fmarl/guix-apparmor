# guix-apparmor
AppArmor 5 for Guix System, with a service that loads profiles at boot and on
reconfigure.  Needs Linux 6.17 or later with `apparmor` in `CONFIG_LSM`.

```scheme
(use-modules (guix-apparmor services)
             (guix-apparmor profiles))

(service apparmor-service-type
         (apparmor-configuration
           (profiles (list %librewolf-profile))))
```

Loaded profiles that are not in the configuration get removed.

`dbus` rules only work if the session bus runs `dbus-apparmor` from
`(guix-apparmor packages dbus)`, as `home-dbus-apparmor-service-type` does.
Unlike `home-dbus-service-type`, it counts as started only once the bus
accepts connections, and it starts at login:

```scheme
(use-modules (guix-apparmor home services))

(service home-dbus-apparmor-service-type)
```
