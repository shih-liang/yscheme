(load "../match.ss")
(optimize-level 2)
(define int32?
  (lambda (x)
    (and (integer? x) (>= x (- 0 (expt 2 31))) (<= x (- (expt 2 31) 1)))))

(define int64?
  (lambda (x)
    (and (integer? x) (>= x (- 0 (expt 2 63))) (<= x (- (expt 2 63) 1)))))


(define verify-scheme
  (lambda (x)
    (define Prog
      (lambda (x)
	(match x
	       [(begin ,stmt ,stmt* ...)
		(Statement stmt)
		(if (not (null? stmt*)) (Prog `(begin ,@stmt*)))]
	       [,other (errorf 'parse "invalid program ~s" other)])))
    (define Statement
      (lambda (x)
	(match x
	       [(set! ,var1 ,in64) (guard (int64? in64)) (Var var1)]
	       [(set! ,var1 ,var2) (guard (symbol? var2)) (Var var1) (Var var2)]
	       [(set! ,var1 (,op ,var1 ,in32)) (guard (int32? in32)) (Var var1) (Binop op)]
	       [(set! ,var1 (,op ,var1 ,var2)) (guard (symbol? var2)) (Var var1) (Var var2) (Binop op)]
	       [,other (errorf 'parse "invalid statement ~s" other)])))
    (define Binop
      (lambda (x)
	(match x
	       [+ '+]
	       [- '-]
	       [* '*]
	       [,other (errorf 'parse "Invalid Operator ~s" other)])))
    (define Var
      (lambda (x)
	(match x
	       [r8 'r8]
	       [r9 'r9]
	       [r10 'r10]
	       [r11 'r11]
	       [r12 'r12]
	       [r13 'r13]
	       [r14 'r14]
	       [r15 'r15]
	       [rax 'rax]
	       [rbx 'rbx]
	       [rcx 'rcx]
	       [rdx 'rdx]
	       [rbp 'rbp]
	       [rsi 'rsi]
	       [rdi 'rdi]
	       [,other (errorf 'parse "invalid Register ~s" other)])))		
    (Prog x) x))

(define generate-x86-64
  (lambda (x)
    (define Prog
      (lambda (x)
	(match x
	       [(begin ,stmt ,stmt* ...)
		(Statement stmt)
		(if (not (null? stmt*)) (Prog `(begin ,@stmt*)))]
	       [,other (errorf 'parse "invalid program ~s" other)])))
    (define Statement
      (lambda (x)
	(match x
	       [(set! ,var1 ,in64) (guard (int64? in64)) (printf "movq $~s ,%~s ~%" in64 var1)]
	       [(set! ,var1 ,var2) (guard (symbol? var2)) (printf "movq %~s ,%~s ~%" var2 var1)]
	       [(set! ,var1 (,op ,var1 ,in32)) (guard (int32? in32)) (printf "~s $~s ,%~s ~%" (Binop op) in32 var1)]
	       [(set! ,var1 (,op ,var1 ,var2)) (guard (symbol? var2)) (printf "~s %~s ,%~s ~%" (Binop op) var2 var1)]
	       [,other (errorf 'parse "invalid statement ~s" other)])))
    (define Binop
      (lambda (x)
	(match x
	       [+ 'addq]
	       [- 'subq]
	       [* 'imulq]
	       [,other (errorf 'parse "Invalid Operator ~s" other)])))
    (define Var 
      (lambda (x)
	(match x
	       [r8 'r8]
	       [r9 'r9]
	       [r10 'r10]
	       [r11 'r11]
	       [r12 'r12]
	       [r13 'r13]
	       [r14 'r14]
	       [r15 'r15]
	       [rax 'rax]
	       [rbx 'rbx]
	       [rcx 'rcx]
	       [rdx 'rdx]
	       [rbp 'rbp]
	       [rsi 'rsi]
	       [rdi 'rdi]
	       [,other (errorf 'parse "invalid Register ~s" other)])))
    (printf ".globl _scheme_entry ~%")
    (printf "_scheme_entry: ~%")
    (Prog x)
    (printf "ret ~%")))

(define driver
  (lambda (program)
    (with-output-to-file "t.s"
      (lambda ()
	(generate-x86-64 (verify-scheme program))))))
