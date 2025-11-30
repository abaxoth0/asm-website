;; FASM (flat assembler) - https://flatassembler.net/

format ELF64 executable

sys_write  equ 1
sys_close  equ 3
sys_socket equ 41
sys_accept equ 43
sys_bind   equ 49
sys_listen equ 50
sys_exit   equ 60

;; Probably there are a better way to define such a macro, but i dont really care

macro syscall1 num, a {
    mov rax, num
    mov rdi, a
    syscall
}

macro syscall2 num, a, b {
    mov rax, num
    mov rdi, a
    mov rsi, b
    syscall
}

macro syscall3 num, a, b, c {
    mov rax, num
    mov rdi, a
    mov rsi, b
    mov rdx, c
    syscall
}

STDOUT equ 1
STDERR equ 2

macro write fd, buf, count {
    syscall3 sys_write, fd, buf, count
}

MAX_CONN equ 5

macro listen fd, backlog {
    syscall2 sys_listen, fd, backlog
}

macro close fd {
    syscall1 sys_close, fd
}

AF_INET     equ 2
SOCK_STREAM equ 1

macro socket domain, type, protocol {
    syscall3 sys_socket, domain, type, protocol
}

macro bind sockfd, addr, addr_len {
    syscall3 sys_bind, sockfd, addr, addr_len
}

macro accept sockfd, addr, addr_len {
    syscall3 sys_accept, sockfd, addr, addr_len
}

EXIT_SUCCES  equ 0
EXIT_FAILURE equ 1

macro exit status {
    mov r15, status ; store status
    jmp shutdown
}

macro catch seg {
    cmp rax, 0
    jl  seg
}

segment readable executable
entry main

INADDR_ANY  equ 0
SOCK_PORT   equ 14619 ; 6969

main:
    write   STDOUT, start_msg, start_msg_len

    write   STDOUT, socket_trace_msg, socket_trace_msg_len

    socket  AF_INET, SOCK_STREAM, 0
    catch   error
    mov     qword [sockfd], rax

    write   STDOUT, bind_trace_msg, bind_trace_msg_len

    mov     word [servaddr.sin_family], AF_INET
    mov     word [servaddr.sin_port], SOCK_PORT
    mov     dword [servaddr.sin_addr], INADDR_ANY

    bind    [sockfd], servaddr.sin_family, sizeof_servaddr
    catch   error

    write   STDOUT, listen_trace_msg, listen_trace_msg_len

    listen  [sockfd], MAX_CONN
    catch   error

next_req:
    write   STDOUT, accept_trace_msg, accept_trace_msg_len

    accept  [sockfd], cliaddr.sin_family, cliaddr_len
    catch   error

    mov     qword[connfd], rax

    write   [connfd], response, response_len

    jmp     next_req

error:
    write   STDERR, error_msg, error_msg_len
    exit    EXIT_FAILURE

shutdown:
    close   [sockfd]
    close   [connfd]
    mov     rax, sys_exit
    mov     rdi, r15 ; exit status is stored in r15 register by 'exit' macro
    syscall


segment readable writable

;; db - 1 byte
;; dw - 2 byte
;; dd - 4 bytes
;; dq - 8 bytes

sockfd dq -1
connfd dq -1

struc servaddr_in {
    .sin_family dw 0
    .sin_port   dw 0
    .sin_addr   dd 0
    .sin_zero   dq 0
}

servaddr        servaddr_in
sizeof_servaddr = $ - servaddr.sin_family

cliaddr     servaddr_in
cliaddr_len dd sizeof_servaddr


response db "HTTP/1.1 200 OK", 13, 10 ;; 13 is \r and 10 is \n in ASCII
         db "Content-Type: text/html; charset=utf-8", 13, 10
         db "Connection: close", 13, 10
         db 13, 10
         db "<h1>Hello, World!</h1>", 10
response_len = $ - response

; Log messages

start_msg     db "[INFO] Starting Web Server", 10 ;; 10 is \n is ASCII
start_msg_len = $ - start_msg

ok_trace_msg     db "[TRACE] OK", 10
ok_trace_msg_len = $ - ok_trace_msg

socket_trace_msg     db "[TRACE] Creating a socket...", 10
socket_trace_msg_len = $ - socket_trace_msg

bind_trace_msg     db "[TRACE] Binding the socket...", 10
bind_trace_msg_len = $ - bind_trace_msg

listen_trace_msg     db "[TRACE] Listening to the socket...", 10
listen_trace_msg_len = $ - listen_trace_msg

accept_trace_msg     db "[TRACE] Waiting for client connections...", 10
accept_trace_msg_len = $ - accept_trace_msg

error_msg     db "ERROR", 10
error_msg_len = $ - error_msg

