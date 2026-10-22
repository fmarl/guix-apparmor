;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2026 Florian Marrero Liestmann <f.m.liestmann@fx-ttr.de>

(define-module (guix-apparmor home services)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages admin)
  #:use-module (gnu services)
  #:use-module (guix-apparmor packages dbus)
  #:export (home-dbus-apparmor-configuration
            home-dbus-apparmor-configuration?
            home-dbus-apparmor-configuration-dbus
            home-dbus-apparmor-service-type))

(define-record-type* <home-dbus-apparmor-configuration>
  home-dbus-apparmor-configuration make-home-dbus-apparmor-configuration
  home-dbus-apparmor-configuration?
  (dbus home-dbus-apparmor-configuration-dbus ;file-like
        (default dbus-apparmor)))

(define (dbus-shepherd-services config)
  (define dbus
    (home-dbus-apparmor-configuration-dbus config))

  (list (shepherd-service
          (provision '(dbus))
          (modules '((shepherd support)))
          (start
           #~(lambda _
               (let* ((runtime-dir (or (getenv "XDG_RUNTIME_DIR")
                                       (format #f "/run/user/~a" (getuid))))
                      (config (string-append runtime-dir "/dbus.conf"))
                      (pid-file (string-append runtime-dir "/dbus.pid")))
                 (call-with-output-file config
                   (lambda (port)
                     (format port "\
<!DOCTYPE busconfig PUBLIC \"-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN\"
 \"http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd\">
<busconfig>
  <include>~a</include>
  <pidfile>~a</pidfile>
</busconfig>~%"
                             #$(file-append dbus "/share/dbus-1/session.conf")
                             pid-file)))
                 ((make-forkexec-constructor
                   (list #$(file-append dbus "/bin/dbus-daemon")
                         "--nofork"
                         (string-append "--config-file=" config)
                         (string-append "--address=unix:path=" runtime-dir
                                        "/bus"))
                   #:pid-file pid-file
                   #:log-file (string-append %user-log-dir "/dbus.log"))))))
          (stop #~(make-kill-destructor))
          (documentation "D-Bus session bus"))))

(define (dbus-environment-variables config)
  '(("DBUS_SESSION_BUS_ADDRESS"
     . "unix:path=${XDG_RUNTIME_DIR:-/run/user/$UID}/bus")))

(define (dbus-shell-profile config)
  (list (mixed-text-file
         "dbus-ready"
         "if [ -S \"${XDG_RUNTIME_DIR:-/run/user/$UID}/shepherd/socket\" ]; then"
         "\n  "
         shepherd-for-home
         "/bin/herd start dbus >/dev/null\n"
         "fi\n")))

(define home-dbus-apparmor-service-type
  (service-type
    (name 'home-dbus-apparmor)
    (extensions
     (list (service-extension home-shepherd-service-type
                              dbus-shepherd-services)
           (service-extension home-environment-variables-service-type
                              dbus-environment-variables)
           (service-extension home-shell-profile-service-type
                              dbus-shell-profile)))
    (default-value (home-dbus-apparmor-configuration))
    (description "Run the D-Bus session bus with AppArmor mediation.")))
