;;; © 2016-2017 Marco Heisig - licensed under AGPLv3, see the file COPYING

(in-package :petalisp-internals)

(defgeneric report-condition (condition stream))

;;; It is crucial to differentiate between two kinds of errors -- those
;;; triggered by improper usage of Petalisp and those occurring even though
;;; Petalisp has been used properly. The former are expected to be far more
;;; frequent and part of the everyday user experience, while the latter
;;; should ideally never arise. Needless to say, errors triggered by the
;;; user should emit a detailed and helpful report, while the latter do not
;;; even deserve their own condition type.

(define-condition petalisp-user-error (error)
  ()
  (:report report-condition))

(defun write-symbol-as-sentence (symbol stream)
  (let ((name (symbol-name symbol)))
    ;; upcase the first letter
    (write-char (char-upcase (aref name 0)) stream)
    ;; replace all hyphens in the body
    (loop for index from 1 below (length name) do
      (let ((char (aref name index)))
        (if (char= char #\-)
            (write-char #\space stream)
            (write-char (char-downcase char) stream))))
    ;; write the trailing dot
    (write-char #\. stream)))

(defmethod report-condition ((condition petalisp-user-error) stream)
  (write-symbol-as-sentence (class-name (class-of condition)) stream))

(define-condition broadcast-with-invalid-dimensions
  (petalisp-user-error)
  ((%data-structure :initarg :data-structure :reader data-structure)
   (%index-space :initarg :index-space :reader index-space)))

(define-condition no-common-broadcast-space
  (petalisp-user-error)
  ((%index-spaces :initarg :data-structures :reader index-spaces)))

(define-condition reduction-of-data-structure-with-dimension-zero
    (petalisp-user-error)
  ((%data-structure :initarg :data-structure :reader data-structure)))

(define-condition fusion-of-elements-of-different-dimension
    (petalisp-user-error)
  ((%elements :initarg :elements :reader elements)))

(define-condition reference-to-non-subspace
    (petalisp-user-error)
  ((%data-structure :initarg :data-structure :reader data-structure)
   (%index-space :initarg :index-space :reader index-space)))

(define-condition reference-with-transformation-of-invalid-dimension
    (petalisp-user-error)
  ((%data-structure :initarg :data-structure :reader data-structure)
   (%transformation :initarg :transformation :reader transformation)))