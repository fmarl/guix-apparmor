;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2026 Florian Marrero Liestmann <f.m.liestmann@fx-ttr.de>

(define-module (guix-apparmor services)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (guix-apparmor packages apparmor)
  #:use-module (gnu packages linux)
  #:use-module (gnu services)
  #:use-module (srfi srfi-1)
  #:export (apparmor-configuration
            apparmor-configuration?
            apparmor-configuration-apparmor
            apparmor-configuration-profiles
            apparmor-service-type))

(define-record-type* <apparmor-configuration>
  apparmor-configuration make-apparmor-configuration
  apparmor-configuration?
  (apparmor apparmor-configuration-apparmor ;file-like
            (default apparmor))
  (profiles apparmor-configuration-profiles ;list of file-like
            (default '())))

(define (apparmor-loader config)
  (match-record config <apparmor-configuration> (apparmor profiles)
    (program-file
     "apparmor-load"
     (with-imported-modules '((guix-apparmor build loader))
       #~(begin
           (use-modules (guix-apparmor build loader))
           (exit (load-apparmor-profiles
                  '#$profiles
                  #:parser #$(file-append apparmor "/sbin/apparmor_parser")
                  #:mount #$(file-append util-linux "/bin/mount")
                  #:arguments
                  (list "--config-file"
                        #$(file-append apparmor "/etc/apparmor/parser.conf")
                        "--base" #$(file-append apparmor "/etc/apparmor.d")
                        "--skip-cache"))))))))

(define (apparmor-activation config)
  #~(system* #$(apparmor-loader config)))

(define (add-profiles config profiles)
  (apparmor-configuration
    (inherit config)
    (profiles (append (apparmor-configuration-profiles config) profiles))))

(define apparmor-service-type
  (service-type
    (name 'apparmor)
    (extensions
     (list (service-extension activation-service-type apparmor-activation)
           (service-extension profile-service-type
                              (compose list apparmor-configuration-apparmor))))
    (compose concatenate)
    (extend add-profiles)
    (default-value (apparmor-configuration))
    (description "Load AppArmor profiles at boot and on reconfigure.")))
