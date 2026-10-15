;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2026 Florian Marrero Liestmann <f.m.liestmann@fx-ttr.de>

;; Per-directory local variables for GNU Emacs, following those of Guix.

((nil
  . ((fill-column . 78)
     (tab-width   .  8)
     (sentence-end-double-space . t)))
 (scheme-mode
  .
  ((indent-tabs-mode . nil)

   ;; Guile and Guix forms used here.
   (eval . (put 'lambda* 'scheme-indent-function 1))
   (eval . (put 'match-record 'scheme-indent-function 3))
   (eval . (put 'modify-inputs 'scheme-indent-function 1))
   (eval . (put 'substitute-keyword-arguments 'scheme-indent-function 1))
   (eval . (put 'with-imported-modules 'scheme-indent-function 1))

   ;; Record constructors.
   (eval . (put 'origin 'scheme-indent-function 0))
   (eval . (put 'package 'scheme-indent-function 0))
   (eval . (put 'service-type 'scheme-indent-function 0)))))
