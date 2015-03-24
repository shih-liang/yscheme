(define finalize-locations
  (lambda (x)
    (define Program
      (lambda (x)
	(define map-label-to-def
	  (lambda (label* body*)
	    (map (lambda (label body)
		   `(,label (lambda () ,(Body body))))
		 label* body*)))
	(match x
	       [(letrec ([,label* (lambda () ,body*)] ...) ,body)
		`(letrec ,(map-label-to-def label* body*) ,(Body body))])))
    (define Body
      (lambda (x)
	(match x
	       [(locate ([,uvar* ,loc*] ...) ,tail)
		(Tail tail (map cons uvar* loc*))])))
    (define Tail
      (lambda (x env)
	(match x
	       [(begin ,effts* ... ,tail)
		`(begin ,@(map (lambda (e) (Effect e env)) effts*) ,(Tail tail env))]
	       [(if ,pred ,then ,else)
		`(if ,(Pred pred env) ,(Tail then env) ,(Tail else env))]
	       [(,triv)
		(list (Triv triv env))])))
    (define Pred
      (lambda (x env)
	(match x
	       [(if ,pred1 ,pred2 ,pred3)
		`(if ,(Pred pred1 env) ,(Pred pred2 env) ,(Pred pred3 env))]
	       [(begin ,effect* ... ,pred)
		`(begin ,@(map (lambda (e) (Effect e env)) effect*) ,(Pred pred env))]
	       [(,relop ,triv1 ,triv2)
		`(,relop ,(Triv triv1 env) ,(Triv triv2 env))]
	       [(true) '(true)]
	       [(false) '(false)])))
    (define Effect
      (lambda (x env)
	(match x
	       [(if ,pred ,efft1 ,efft2)
		`(if ,(Pred pred env) ,(Effect efft1 env) ,(Effect efft2 env))]
	       [(begin ,effect* ... ,effect)
		`(begin ,@(map (lambda (e) (Effect e env)) effect*) ,(Effect effect env))]
	       [(set! ,var (,binop ,triv1 ,triv2))
		`(set! ,(Var var env) (,binop ,(Triv triv1 env) ,(Triv triv2 env)))]
	       [(set! ,var ,triv)
		`(set! ,(Var var env) ,(Triv triv env))]
	       [(nop) '(nop)])))
    (define Loc (lambda (x) x))
    (define Var
      (lambda (x env)
	(let ((find (assoc x env)))
	  (if find
	      (cdr find)
	      x))))
    (define Triv
      (lambda (x env)
	(if (or (integer? x) (label? x))
	    x
	    (Var x env))))
    (Program x)))

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
