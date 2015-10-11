这是比较接近王垠原始代码的一个版本。它的代码经常会lost in the future，所以我fork了一份。

王垠的放出来的代码是运行不了的，所以这里补全了一些东西，让它能够运行。

这些补全都是从网上收集的。相关版权的都属于各自原始出处。

文档来自于[这里](https://github.com/spiritbear/Grad-School-Code)，根据代码来推测，作者可能当时跟王垠同班。

P423是Indiana大学王垠当时选的编译器的课程，[这里](https://github.com/srwaggon/p423)和[这里](https://github.com/keyanzhang/p423-compiler)都能找到一些课程的代码。

这里有部分我翻译成[中文的资料](http://zenlife.tk/nanopass0.md)。


# 运行

[chez scheme](http://www.scheme.com/)有一个免费的解释器版本petite，去找到并下载。

    cd yscheme
    petite
    (load "compiler.ss")
    (test-one '(lambda (x) (+ x 1)))

可以看到最后的输出：

    generate-x86-64:
        .globl _scheme_entry
    _scheme_entry:
        pushq %rbx
        pushq %rbp
        pushq %r12
        pushq %r13
        pushq %r14
        pushq %r15
        movq %rdi, %rbp
        movq %rsi, %rdx
        leaq _scheme_exit(%rip), %r15
        movq %rdx, %rax
        addq $8, %rdx
        addq $2, %rax
        movq %rax, %rcx
        leaq L2(%rip), %rax
        movq %rax, -2(%rcx)
        movq %rcx, %rax
        jmp *%r15
    L2:
        movq %r9, %rax
        addq $8, %rax
        jmp *%r15
    _scheme_exit:
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        popq %rbx
        ret

自己测试可以运行可以调用test-one函数。有一些参数是可以设置的，比如：

    (tracer #f) 关闭中间过程的输出
    (compiler-passes '(<spec> ...)) 设置运行的pass
    (test-one '<program>) 测试一段代码

具体的可以去看driver.ss文件

-----------------------------------

# YScheme - an experimental compiler for Scheme


This is the final submission for a compiler course I took from <a
href="http://en.wikipedia.org/wiki/R._Kent_Dybvig">Kent Dybvig</a> at Indiana
University. The compiler compiles a significant subset of Scheme into X64
assembly and then links it with a runtime system written in C. I made attempts
to simplify and innovate the compiler, so it is quite different from Kent's
original design.

In Kent's words, I put myself into trouble each week by doing things differently
and then get myself out of it. Sometimes I did better than his compiler,
sometimes, worse. But eventually I passed all his tests and got an A+.

A notable thing of this compiler is its use of _high-order evaluation contexts_,
an advanced technique used in <a
href="https://github.com/yinwang0/lightsabers/blob/master/cps.ss">CPS
transformers</a>, which resulted sometimes in much simpler and shorter code.


### Copyright

Copyright (c) 2008-2014 Yin Wang, All rights reserved

Only the main compiler code is here. I don't have copyright of the rest of the
code (test framework, runtime system etc)


### References

For a history of the important compiler techniques contained in this compiler,
please refer to Kent's paper:

<a href="http://www.cs.indiana.edu/~dyb/pubs/hocs.pdf">The Development of Chez
Scheme</a>


For details of the compiler framework developed for the course, please refer to

<https://github.com/akeep/nanopass-framework>


For more information about CPS transformation, please refer to Andrew Appel's
book:

<a
href="http://www.amazon.com/Compiling-Continuations-Andrew-W-Appel/dp/052103311X">Compiling
with Continuations</a>

and Danvy and Filinski's paper

<a href="http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.46.84">Representing control: a study of the CPS transformation (1992)</a>
