  .bss
BUFFER:
  .space 256
  .data
SIZE_ALPHA:
  .quad 26
BELOW_UPPER:
  .byte 63
TOP_UPPER:
  .byte 90
BELOW_LOWER:
  .byte 96
ABOVE_LOWER: 
  .byte 123
  .text
  .global _start
  .global print
  .global exit
  
;# Program entry point
;# TODO #1: rewrite this to read in a string from the user to use as input instead of "Hello world!"
_start:
  movq $0, %rax
  movq $0, %rdi
  leaq BUFFER, %rsi
  movq $255, %rdx
  syscall
  
  leaq BUFFER, %rdi
  addq %rax, %rdi
  movb $0, 0(%rdi)
  
  leaq BUFFER, %rdi
  movq $1, %rsi
  pushq %rdi
  call shift
  popq %rdi
  call print
  call exit

;# caesar shifts a null-terminated string
;# rdi: address of string
;# rsi: size of shift
shift:
  pushq %rbp
  movq %rsp, %rbp
;# zero out r11 so we know the upper 56 bits are clear later
  movq $0, %r11
;# first: reduce the shift mod 26
  pushq %rdi
  movq %rsi, %rax
  cqto 
  idivq (SIZE_ALPHA)
  movq %rdx, %rsi
  popq %rdi
  jmp shift_loop_cond
shift_loop:
;# this is like a 'switch statement' to change the action based on the character value
  cmpb (BELOW_UPPER), %r11b
  jbe shift_loop_next
  cmpb (TOP_UPPER), %r11b
  jbe shift_loop_upper
  cmpb (BELOW_LOWER), %r11b
  jbe shift_loop_next
  cmpb (ABOVE_LOWER), %r11b
  jge shift_loop_next
;# only remaining case is that the character is lowercase
shift_loop_lower:
  pushq %rdi
  movb %r11b, %dil
  call shift_lower
  popq %rdi
  movb %al, 0(%rdi)
  jmp shift_loop_next
shift_loop_upper:
  pushq %rdi
  movb %r11b, %dil
  call shift_upper
  popq %rdi
  movb %al, 0(%rdi)
shift_loop_next:
  addq $1, %rdi
shift_loop_cond:
  movb 0(%rdi), %r11b
  test %r11b, %r11b
  jnz shift_loop
  popq %rbp
  ret

;# TODO #2
;# caesar shifts a lowercase character
;# rdi: value of character (in byte dil)
;# rsi: size of shift (between -25 and 25, inclusive)
;# rax after execution: shifted character
shift_lower:
  pushq %rbp
  movq %rsp, %rbp

  movb %dil, %al
  subb $'a', %al

  movsbl %al, %eax
  addq %rsi, %rax

  cmpq $0, %rax
  jge shift_lower_not_negative
  addq $26, %rax

shift_lower_not_negative:
  cmpq $26, %rax
  jl shift_lower_after_wrapping
  subq $26, %rax

shift_lower_after_wrapping:
  addq $'a', %rax
  popq %rbp
  ret

;# TODO #3
;# caesar shifts an uppercase character
;# rdi: value of character (in byte dil)
;# rsi: size of shift (between -25 and 25, inclusive)
;# rax after execution: shifted character
;# currently this just always returns 'U' as a placeholder
shift_upper:
  pushq %rbp
  movq %rsp, %rbp

  movb %dil, %al
  addb %sil, %al

  cmpb $90, %al
  jle shift_upper_less_equal
  subb $26, %al

shift_upper_less_equal:
  cmpb $65, %al
  jge shift_upper_greater_equal
  addb $26, %al

shift_upper_greater_equal:
  popq %rbp
  ret 


;# prints null-terminated string to stdout
;# rdi: address of string
print:
  pushq %rbp
  movq %rsp, %rbp
  pushq %rdi
  call strlen
  movq %rax, %rdx
  popq %rsi
  movq $1, %rax
  movq $1, %rdi
  syscall
  popq %rbp
  ret

;# returns length of null-terminated string
;# (including null byte)
;# rdi: pointer to string
strlen:
  pushq %rbp
  movq %rsp, %rbp
  movq $0, %rax
  jmp init_loop
loop:
  addq $1, %rax
  addq $1, %rdi
init_loop:
  movb 0(%rdi), %r11b
  testb %r11b, %r11b
  jnz loop
  popq %rbp
  ret

;# Terminates program with exit code 0 (success)
exit:
  movq $60, %rax
  movq $0, %rdi
  syscall
