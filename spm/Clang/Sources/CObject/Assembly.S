#if defined(__arm64__)
.globl _assembly_value
.p2align 2
_assembly_value:
    mov w0, #9
    ret
#elif defined(__x86_64__)
.globl _assembly_value
.p2align 4, 0x90
_assembly_value:
    movl $9, %eax
    retq
#else
#error Unsupported architecture
#endif
