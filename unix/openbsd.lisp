;;
;;  adams  -  Remote system administration tools
;;
;;  Copyright 2013,2014 Thomas de Grivel <thomas@lowh.net>
;;
;;  Permission to use, copy, modify, and distribute this software for any
;;  purpose with or without fee is hereby granted, provided that the above
;;  copyright notice and this permission notice appear in all copies.
;;
;;  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
;;  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
;;  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
;;  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
;;  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
;;  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
;;  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
;;

(in-package :adams)

(in-re-readtable)

(define-resource-class openbsd-pkg (pkg)
  ()
  ((probe-openbsd-pkg :properties (:name :version :flavors))))

(define-syntax pkg_info<1> (name version flavors)
  #~|\s*((?:[^-\s]+)(?:-[^-0-9\s][^-\s]*)*)-([0-9][^-\s]*)(-[^\s]+)?|
  "Syntax for pkg_info(1) on OpenBSD"
  (values name version (re-matches #~|[^-]+| flavors)))

(defgeneric probe-openbsd-pkg (resource os))

(defmethod probe-openbsd-pkg ((pkg openbsd-pkg) (os os-openbsd))
  (let ((id (resource-id pkg)))
    (multiple-value-bind #1=(name version flavors)
      (iter (pkg_info<1> #1# in
                         (run "pkg_info | egrep ~A" (sh-quote (str "^" id "-"))))
            (when (string= id name)
              (return (values* #1#))))
      (properties* #1#))))

(defmethod probe-installed-packages% ((host host) (os os-openbsd))
  (with-host host
    (iter (pkg_info<1> #1=(name version flavors)
                       in (run "pkg_info"))
          (for pkg = (resource 'openbsd-pkg name))
          (add-probed-properties pkg (properties* #1#))
          (collect pkg))))

(defun probe-installed-packages (&optional (host *host*))
  (probe-installed-packages% host (host-os host)))

#+nil
(clear-resources)

#+nil
(describe-probed (resource 'openbsd-pkg "emacs"))

#+nil
(probe-installed-packages *localhost* (host-os *localhost*))

#+nil
(run "pkg_info -q | grep emacs-")