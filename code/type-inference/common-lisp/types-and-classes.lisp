;;;; © 2016-2019 Marco Heisig         - license: GNU AGPLv3 -*- coding: utf-8 -*-

(in-package #:petalisp.type-inference)

(define-rule subtypep (type-1 type-2 &optional (environment nil environment-p))
  (with-constant-folding (subtypep ((wrapper-ntype type-1) type-specifier)
                                   ((wrapper-ntype type-2) type-specifier)
                                   ((if environment-p
                                        (wrapper-ntype environment)
                                        (ntype 'null))
                                    t))
    (rewrite-default (ntype 'type-specifier))))

(define-rule type-of (object)
  (rewrite-default (ntype 'type-specifier)))

(define-rule typep (object type-specifier &optional (environment nil environment-p))
  (let ((object-ntype (wrapper-ntype object))
        (type-specifier-ntype (wrapper-ntype type-specifier))
        (environment-ntype (if environment-p
                               (wrapper-ntype environment)
                               (ntype 'null))))
    (with-constant-folding (typep (object-ntype t)
                                  (type-specifier-ntype type-specifier)
                                  (environment-ntype t))
      (if (eql-ntype-p type-specifier-ntype)
          (let ((ntype (ntype type-specifier-ntype)))
            (cond ((ntype-subtypep object-ntype ntype)
                   (rewrite-default (ntype '(not null))))
                  ((ntype-subtypepc1 object-ntype ntype)
                   (rewrite-as nil))
                  (t (rewrite-default (ntype 'generalized-boolean)))))
          (rewrite-default (ntype 'generalized-boolean))))))