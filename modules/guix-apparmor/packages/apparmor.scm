;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2026 Florian Marrero Liestmann <f.m.liestmann@fx-ttr.de>

(define-module (guix-apparmor packages apparmor)
  #:use-module ((gnu packages apparmor) #:prefix guix:)
  #:use-module (gnu packages compression)
  #:use-module (guix git-download)
  #:use-module (guix packages))

(define-public libapparmor
  (package
    (inherit guix:libapparmor)
    (version "5.0.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://gitlab.com/apparmor/apparmor")
             (commit (string-append "v" version))))
       (file-name (git-file-name "libapparmor" version))
       (sha256
        (base32 "1629c3xd5mkhdwvlk52acc6pigj9zn9703lh1d6ax2pqphv3krra"))))))

(define-public apparmor
  (package
    (inherit guix:apparmor)
    (version (package-version libapparmor))
    (source
     (package-source libapparmor))
    (inputs (list `(,zstd "lib")))
    (propagated-inputs (list libapparmor))))
