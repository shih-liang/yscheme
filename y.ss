(define generate-x86-64
  (lambda (x)
    (define Program
      (lambda (x)
	(match x
	       [(begin ,stmt ,stmt* ...)
		(Statement stmt) (if (not (null? stmt*)) (Program `(begin ,@stmt*)))]
	       [,other (errorf 'parse "invalid Program ~s" other)])))
    (define Statement
      (lambda (x)
	(match x
	       [(set! ,var1 ,int64) (guard (int64? int64)) (printf "movq $~s, %~s ~%" int64 var1)]
	       [(set! ,var1 ,var2) (guard (symbol? var2)) (printf "movq %~s, %~s ~%" var2 var1)]
	       [(set! ,var1 (,op ,var1 ,int32)) (guard (int32? int32)) (printf "~s $~s, %~s ~%" (Binop op) int32 var1)]
	       [(set! ,var1 (,op ,var1 ,var2)) (guard (symbol? var2)) (printf "~s %~s, %~s ~%" (Binop op) var2 var1)]
	       [,other (errorf 'parse "invalid Statement ~s" other)])))
    (define Binop
      (lambda (x)
	(match x
	       [+ 'addq]
	       [- 'subq]
	       [* 'imulq]
	       [,other (errorf 'parse "invalid Binop ~s" other)])))
    (printf ".global _scheme_entry ~%")
    (printf "_scheme_entry: ~%")
    (Program x)
    (printf "ret ~%")))

	    

