;;; © 2016 Marco Heisig - licensed under AGPLv3, see the file COPYING

(in-package :petalisp)

(define-class strided-array-source (strided-array source) ())

(define-class strided-array-from-lisp-array (strided-array-source)
  (lisp-array))

(define-class strided-array-from-hdf5 (strided-array-source)
  (path))

(defun array-ranges (array)
  (map 'vector
       (lambda (end)
         (range 0 1 (1- end)))
       (array-dimensions array)))

(defmethod source ((object t) &rest arguments)
  (assert (null arguments))
  (let ((array (or
                (and (typep object 'simple-array) object)
                (make-array () :initial-element object
                               :element-type (type-of object)))))
    (make-instance
     'strided-array-from-lisp-array
     :lisp-array array
     :ranges (array-ranges array))))

(defmethod source ((object (eql 'hdf5)) &key pathname)
  (make-instance
   'strided-array-from-hdf5
   :pathname pathname))
