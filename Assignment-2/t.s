  .globl _scheme_entry
_scheme_entry:
    pushq %rbx
    pushq %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    movq %rdi, %rbp
    leaq _scheme_exit(%rip), %r15
    movq $17, %rax
    jmp L1
L1:
    movq %rax, 0(%rbp)
    addq %rax, %rax
    addq 0(%rbp), %rax
    jmp *%r15
_scheme_exit:
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
    popq %rbx
    ret