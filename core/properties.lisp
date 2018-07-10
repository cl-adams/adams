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

;;  Properties implemented as property lists

(defun properties (&rest keys-and-values)
  (apply #'list keys-and-values))

(defmacro properties* (&rest vars)
  (when (and (consp (first vars))
             (endp (rest vars)))
    (setq vars (first vars)))
  (let ((properties))
    (loop
       (when (endp vars)
         (return))
       (let ((v (pop vars)))
         (push (make-keyword v) properties)
         (push v properties)))
    (cons 'list
          (nreverse properties))))

(defmacro values* (&rest vars)
  (when (and (consp (first vars))
             (endp (rest vars)))
    (setq vars (first vars)))
  `(values ,@vars))

(defmacro get-property (property properties)
  `(getf ,properties ,property +undefined+))

(defun get-properties (keys properties)
  (let ((plist))
    (loop
       (when (endp keys)
         (return))
       (let* ((k (pop keys))
              (v (get-property k properties)))
         (unless (eq v +undefined+)
           (push k plist)
           (push v plist))))
    (nreverse plist)))

(defmethod compare-property-values (resource property value1 value2)
  (equalp value1 value2))

(defmethod compare-property-values (resource property
                                    (value1 local-time:timestamp)
                                    (value2 local-time:timestamp))
  (local-time:timestamp= value1 value2))

(defmethod merge-property-values (resource property (old null) new)
  new)

(defmethod merge-property-values (resource property old new)
  (unless (compare-property-values resource property old new)
    (warn "Conflicting values for property ~A in
~A
 old: ~S
 new: ~S
Keeping old value by default."
          property resource old new)
    old))

(defun merge-properties (resource &rest properties)
  (let* ((result (pop properties))
         (tail (last result)))
    (flet ((push-result (&rest args)
             (dolist (x args)
               (let ((new-tail (list x)))
                 (if (endp result)
                     (setf result new-tail
                           tail new-tail)
                     (setf (cdr tail) new-tail
                           tail new-tail))))))
      (dolist (plist properties)
        (loop
           (when (endp plist)
             (return))
           (let* ((key (pop plist))
                  (val (pop plist))
                  (result-val (getf result key +undefined+)))
             (cond ((eq result-val +undefined+)
                    (push-result key val))
                   ((not (equalp result-val val))
                    (setf (getf result key)
                          (merge-property-values resource key result-val val))))))))
    result))
