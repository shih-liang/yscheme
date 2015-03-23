(define expose-frame-var
  (lambda (x)
    (define Program
      (lambda (x)
	(define map-label-to-def
	  (lambda (label* body*)
	    (map (lambda (label body)
		   (let ((transformed-body (Tail body)))
		     `(,label (lambda () ,transformed-body))))
		 label* body*)))
	(match x
	       [(letrec ([,label* (lambda () ,tail*)] ...) ,tail-p)
		`(letrec ,(map-label-to-def label* tail*) ,(Tail tail-p))])))
    (define Tail
      (lambda (x)
	(match x
	       [(begin ,effts* ... ,tail-p)
		`(begin ,@(map Effect effts*) ,(Tail tail-p))]
	       [,triv
		(Triv triv)])))
    (define Effect
      (lambda (x)
	(match x
	       [(set! ,var (,binop ,triv1 ,triv2))
		`(set! ,(Var var) (,binop ,(Triv triv1) ,(Triv triv2)))]
	       [(set! ,var ,triv)
		`(set! ,(Var var) ,(Triv triv))])))
    (define Var
      (lambda (var)
	(if (frame-var? var) 
	    (make-disp-opnd 'rbp (* 8 (frame-var->index var)))
	    var)))
    (define Triv
      (lambda (t)
	(if (frame-var? t)
	    (make-disp-opnd 'rbp (* 8 (frame-var->index t)))
	    t)))
    (Program x)))

(define flatten-program
  (lambda (x)
    (define Program
      (lambda (x)
	(define make-body
	  (lambda (label* tail*)
	    (apply append 
		   (map (lambda (label tail)
			  `(,label ,@(Tail tail)))
			label* tail*))))
	(match x
	       [(letrec ([,label* (lambda () ,tail*)] ...) ,tail)
		`(code ,@(Tail tail) ,@(make-body label* tail*))])))
    (define Tail
      (lambda (x)
	(match x
	       [(begin ,effect* ... ,tail)
		`(,@effect* ,(Tail tail))]
	       [(,triv)
		`(jump ,triv)])))
    (Program x)))

(define generate-x86-64
  (lambda (x)
    (define Program
      (lambda (x)
	(match x
	       [(code ,stmt ,stmt* ...)
		(Statement stmt) (if (not (null? stmt*)) (Program `(code ,@stmt*)))]
	       [,other (errorf 'parse "invalid Program ~s" other)])))
    (define Statement
      (lambda (stmt)
	(match stmt
	       [(set! ,reg ,lbl) (guard (label? lbl)) (emit 'leaq lbl reg)]
	       [(set! ,var1 (,op ,var1 ,opnd)) (emit (Binop op) opnd var1)]
	       [(set! ,var ,opnd) (emit 'movq opnd var)]
	       [(jump ,opnd) (emit-jump 'jmp opnd)]
	       [,var (guard (label? var)) (emit-label var)]
	       )))
    (define Binop
      (lambda (x)
	(match x
	       [+ 'addq]
	       [- 'subq]
	       [* 'imulq]
	       [logand 'andq]
	       [logor 'orq]
	       [sra 'sraq]
	       [,other (errorf 'parse "invalid Binop ~s" other)])))
    (printf ".global _scheme_entry ~%")
    (printf "_scheme_entry: ~%")
    (Program x)
    (printf "ret ~%")))
