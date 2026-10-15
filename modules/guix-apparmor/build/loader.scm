;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2026 Florian Marrero Liestmann <f.m.liestmann@fx-ttr.de>

(define-module (guix-apparmor build loader)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:export (load-apparmor-profiles))

(define %securityfs
  "/sys/kernel/security")

(define %policy
  (string-append %securityfs "/apparmor"))

(define (report message . arguments)
  (apply format
         (current-error-port)
         (string-append "apparmor: " message "~%") arguments) #f)

(define (read-lines port)
  (let loop
    ((lines '()))
    (let ((line (read-line port)))
      (if (eof-object? line)
          (reverse lines)
          (loop (cons line lines))))))

(define (mount-securityfs mount)
  (unless (file-exists? (string-append %securityfs "/lsm"))
    (system* mount "-t" "securityfs" "securityfs" %securityfs)))

(define (profile-names parser arguments file)
  (let* ((port (apply open-pipe* OPEN_READ parser
                      (append arguments
                              (list "--names" file))))
         (names (read-lines port)))
    (and (zero? (close-pipe port)) names)))

(define (loaded-profiles)
  (map (lambda (line)
         (substring line 0
                    (string-rindex line #\space)))
       (call-with-input-file (string-append %policy "/profiles")
         read-lines)))

(define (remove-profile name)
  (call-with-output-file (string-append %policy "/.remove")
    (cut display name <>)))

(define (stale? known name)
  (not (or (member name known)
           (string-contains name "//"))))

(define (load-profile parser arguments file)
  (or (zero? (apply system* parser
                    (append arguments
                            (list "--replace" file))))
      (report "failed to load ~a" file)))

(define (remove-stale-profiles parser arguments profiles)
  (let ((names (map (cut profile-names parser arguments <>) profiles)))
    (if (every identity names)
        (begin
          (for-each remove-profile
                    (filter (cute stale?
                                  (concatenate names) <>)
                            (loaded-profiles))) #t)
        (report "cannot read the profile names, keeping stale profiles"))))

(define* (load-apparmor-profiles profiles
                                 #:key parser mount
                                 (arguments '()))
  (mount-securityfs mount)
  (cond
    ((not (file-exists? %policy))
     (report "not enabled in the kernel, skipping"))
    ((every identity
            (map (cut load-profile parser arguments <>) profiles))
     (remove-stale-profiles parser arguments profiles))
    (else (report "keeping stale profiles after load errors"))))
