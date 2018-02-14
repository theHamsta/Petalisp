;;; © 2016-2018 Marco Heisig - licensed under AGPLv3, see the file COPYING

(uiop:define-package :petalisp/test-suite/test-suite
  (:use :closer-common-lisp :alexandria :fiveam)
  (:use
   :petalisp/utilities/all
   :petalisp/core/data-structures/all
   :petalisp/core/transformations/all
   :petalisp/examples/jacobi
   :petalisp/examples/red-black-gauss-seidel
   :petalisp/examples/linear-algebra
   :petalisp)
  (:export
   #:run-test-suite))

(in-package :petalisp/test-suite/test-suite)

(in-suite* petalisp)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Utilities

(test |(identical)|
  (is-true (identical '(1 1 1)))
  (is-true (identical #(1 1.0 1/1) :test #'=))
  (is-true (identical '(1 2.0 6/2 4d0) :key #'numberp :test #'eq))
  (is-true (identical "aaaAaa" :test #'char= :key #'char-upcase)))

(test scaled-permutation-matrix
  (is (scaled-permutation-matrix?
       (scaled-permutation-matrix 3 3 #(0 1 2) #(5 4 3))))
  (signals error
    (scaled-permutation-matrix 1 1 #(2) #(1)))
  (signals error
    (scaled-permutation-matrix 2 2 #(0 0) #(1 1))))

(test |(matrix-product scaled-permutation-matrix vector)|
  (is (equalp
       #(10 8)
       (matrix-product
        (scaled-permutation-matrix 2 2 #(1 0) #(2 2))
        #(4 5)))))

(test |(matrix-product scaled-permutation-matrix scaled-permutation-matrix)|
  (is (equalp
       (scaled-permutation-matrix 2 2 #(0 1) #(8 6))
       (matrix-product
        (scaled-permutation-matrix 2 2 #(1 0) #(2 2))
        (scaled-permutation-matrix 2 2 #(1 0) #(3 4)))))
  (is (equalp
       (scaled-permutation-matrix 3 5 #(0 0 0) #(0 0 0))
       (matrix-product
        (scaled-permutation-matrix 3 7 #(0 0 0) #(0 0 0))
        (scaled-permutation-matrix 7 5 #(0 1 2 3 4 0 0) #(6 6 6 6 6 0 0))))))

(test |(matrix-product scaled-permutation-matrix list)|
  (is (equalp
       '(0 foo 84 (* 3 foo))
       (matrix-product
        (scaled-permutation-matrix 4 4 #(0 1 2 3) #(0 1 2 3))
        '(foo foo 42 foo)))))

(test |(matrix-inverse scaled-permutation-matrix)|
  (is (equalp
       (scaled-permutation-matrix 4 4 #(2 0 1 3) #(2 3 4 5))
       (matrix-inverse
        (scaled-permutation-matrix 4 4 #(1 2 0 3) #(1/3 1/4 1/2 1/5))))))

(test |(identity-matrix? scaled-permutation-matrix)|
  (is-true  (identity-matrix? (scaled-permutation-matrix 3 3 #(0 1 2) #(1 1 1))))
  (is-false (identity-matrix? (scaled-permutation-matrix 3 3 #(0 1 2) #(1 2 1))))
  (is-false (identity-matrix? (scaled-permutation-matrix 3 3 #(1 0 2) #(1 1 1)))))

(test |(extended-euclid)|
  (flet ((? (u v)
           (multiple-value-bind (u1 u3) (extended-euclid u v)
             (is (= (gcd u v) u3))
             (if (zerop v)
                 (is (= u3 (* u u1)))
                 (is (integerp (/ (- u3 (* u u1)) v)))))))
    (? 0 0)
    (? 1 0)
    (? 0 1)
    (? (expt 6 40) (expt 9 40))
    (for-all ((u (generator 'integer :minimum 0))
              (v (generator 'integer :minimum 0)))
      (? u v))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Ranges

(test |(generator 'range)|
  (let ((max-size 10)
        (max-extent 100))
    (for-all ((range (generator 'range :max-extent max-extent
                                       :max-size max-size)))
      (is (<= (abs (range-start range)) max-extent))
      (is (<= (abs (range-end range)) max-extent))
      (is (<= (range-size range) max-size)))))

(test |(difference range)|
  (for-all ((a (generator 'range :max-extent 100)))
    (for-all ((b (generator 'range :max-extent 100
                                  :intersecting a)))
      (is (equalp a (range-fusion
                     (cons
                      (range-intersection a b)
                      (range-difference a b))))))))

(test |(intersection range)|
  (let ((fiveam::*num-trials* (ceiling (sqrt fiveam::*num-trials*))))
    (for-all ((a (generator 'range :max-extent 10000)))
      (for-all ((b (generator 'range :max-extent 10000
                                     :intersecting a)))
        (let ((intersection (range-intersection a b)))
          (is-true (range-intersection? intersection a))
          (is-true (range-intersection? intersection b))
          (is (not (range-difference intersection a)))
          (is (not (range-difference intersection b))))))))

(test range
  (is (range? (range 0 0 0)))
  (signals error (range 0 0 1))
  (for-all ((start (generator 'integer))
            (step (generator 'integer :minimum 1))
            (end (generator 'integer)))
    (is (range? (range start step end)))
    (is (= (range-size (range start step end))
           (1+ (floor (abs (- start end)) (abs step)))))
    (is (equalp (range start step end)
                (range start (- step) end)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Strided Array Index Spaces

(test |(index-space-difference strided-array-index-space)|
  (let ((fiveam::*num-trials* (ceiling (sqrt fiveam::*num-trials*))))
    (for-all ((a (generator 'strided-array-index-space
                            :dimension 3
                            :max-extent 40)))
      (for-all ((b (generator 'strided-array-index-space
                              :dimension 3
                              :intersecting a
                              :max-extent 40)))
        (is (index-space-equality a (apply #'index-space-union
                                           (index-space-intersection a b)
                                           (index-space-difference a b))))))))

(test |(index-space-intersection strided-array-index-space)|
  (flet ((? (a b result)
           (is (index-space-equality result (index-space-intersection a b)))))
    (?  (σ) (σ) (σ))
    (? (σ (0 9) (0 9)) (σ (2 10) (2 10)) (σ (2 9) (2 9)))
    (? (σ (1 2 3) (0 3 6)) (σ (1 1 3) (0 2 6)) (σ (1 2 3) (0 6 6)))))

(test |(generic-unery-funcall affine-transformation strided-array-index-space)|
  (flet ((? (object transformation result)
           (is (index-space-equality result (funcall transformation object)))
           (is (index-space-equality object (funcall (inverse transformation) result)))))
    (? (σ (1 1 1)) (τ (m) ((1+ m)))
       (σ (2 1 2)))
    (? (σ (0 9) (0 5)) (τ (m n) (n m))
       (σ (0 5) (0 9)))
    (? (σ (1 1) (2 2) (3 3)) (τ (1 2 3) (4))
       (σ (4 4)))
    (? (σ (2 2)) (τ (m) (1 m 3))
       (σ (1 1) (2 2) (3 3)))
    (? (σ (0 5 10) (0 7 21))
       (τ (m n)
          ((+ (* 2 n) 5)
           (+ (* 3 m) 99)))
       (σ (5 14 47) (99 15 129)))
    (? (σ (0 0) (0 0) (0 0) (0 0) (0 0))
       (τ (a 0 c 0 e) (0 a 0 c 0 e 0))
       (σ (0 0) (0 0) (0 0) (0 0) (0 0) (0 0) (0 0)))
    (signals error
      (funcall (τ (1 m) (m 1)) (σ (0 0) (0 0))))))

(test |(subdivide strided-array-index-space)|
  (flet ((? (&rest args)
           (let ((result (subdivision args)))
             ;; check for disjointness
             (let (intersections)
               (when (> (length result) 1)
                 (map-combinations
                  (lambda (x)
                    (push (apply #'index-space-intersection x) intersections))
                  result :length 2))
               (is (every #'null intersections)))
             ;; check for coverage
             (let ((union (apply #'index-space-union result)))
               (is-true (every (lambda (x) (subspace-p x union)) args))))))
    (? (σ (1 1 4)) (σ (1 2 5)))
    (? (σ (1 1 10) (1 1 10))
       (σ (5 1 10) (5 1 10)))
    (?  (σ (2 2 4)) (σ (3 1 3)) (σ (3 1 3)))))

(test |(subspace-p strided-array-index-space)|
  (is (subspace-p (σ (1 1 2)) (σ (0 1 3))))
  (is (subspace-p (σ (0 4 8)) (σ (0 2 10))))
  (is (subspace-p (σ (0 6 120) (1 1 100))
                  (σ (0 2 130) (0 1 101)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Whole Program Tests

(defun compute! (&rest arguments)
  (is-true (apply #'compute arguments)))

(defun ndarray (n &optional (length 10))
  "Create a LENGTH^N array of double floats."
  (generate-instance 'array
                     :element-type 'double-float
                     :dimensions (make-list n :initial-element length)))

(defmacro with-testing-virtual-machine (&body body)
  `(call-with-testing-virtual-machine
    (lambda () ,@body)))

(defun call-with-testing-virtual-machine (thunk)
  (let ((*virtual-machine*
          (make-instance 'testing-virtual-machine
            :virtual-machines
            (list
             (make-instance 'reference-virtual-machine)
             (make-instance 'common-lisp-virtual-machine)))))
    (funcall thunk)))

(test petalisp-api
  (with-testing-virtual-machine
    (compute! (α #'+ 2 3))
    (compute! (α #'+ #(2 3 4) #(5 4 3)))
    (compute! (-> #(1 2 3) (τ (i) ((- i)))))
    (compute! (fuse* (-> 0.0 (σ (2 4) (2 4)))
                     (-> 1.0 (σ (3 3) (3 3)))))))

(test jacobi
  (with-testing-virtual-machine
    (compute! (jacobi (ndarray 1) :iterations 2))
    (compute! (jacobi (ndarray 2) :iterations 2))
    (compute! (jacobi (ndarray 3) :iterations 2))
    (compute! (jacobi (ndarray 3) :iterations 5))))

(test red-black-gauss-seidel
  (with-testing-virtual-machine
    (compute! (red-black-gauss-seidel (ndarray 1) :iterations 2))
    (compute! (red-black-gauss-seidel (ndarray 2) :iterations 2))
    (compute! (red-black-gauss-seidel (ndarray 3) :iterations 2))
    (compute! (red-black-gauss-seidel (ndarray 3) :iterations 5))))

(test linear-algebra
  (with-testing-virtual-machine
    (loop for dimension upto 2 do
      (compute! (transpose (ndarray dimension))))
    (let ((a (ndarray 2))
          (b (ndarray 2)))
      (compute! (matmul a b)))
    (compute! (dot #(1 2 3) #(4 5 6)))
    (compute! (norm #(1 2 3)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Test Suite Interface

(defun run-test-suite (&optional debug)
  (format t "~&== Testing Petalisp ==~%")
  (print-platform-information)
  (print-system-statistics :petalisp)
  (print-package-statistics :petalisp)
  (format t "~&Git revision: ~a" (system-git-revision :petalisp))
  (let ((*on-error*   (if debug :debug *on-error*))
        (*on-failure* (if debug :debug *on-failure*)))
    (fiveam:run! 'petalisp)))
