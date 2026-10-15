;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2026 Florian Marrero Liestmann <f.m.liestmann@fx-ttr.de>

(define-module (guix-apparmor profiles)
  #:use-module (guix gexp)
  #:export (%librewolf-profile))

(define %librewolf-profile
  (local-file "profiles/librewolf"))
