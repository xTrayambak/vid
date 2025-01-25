	.section .data
consts_0: 
	.asciz "Hello Vid!"

	.section .text
	.global _start
	.extern puts
_start:
	lea consts_0(%rip), %rdi
	call puts
	
	mov $60, %eax
	xor %edi, %edi
	syscall
