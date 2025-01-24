	.section .data
consts_0: 
	.asciz "Hello Vid!"

	.section .text
	.global _start
	.extern printf
_start:
	lea consts_0(%rip), %rdi
	xor %eax, %eax
	call printf
	
	mov $60, %eax
	xor %edi, %edi
	syscall
