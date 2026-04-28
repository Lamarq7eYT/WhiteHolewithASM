default rel
bits 64

%define CS_VREDRAW 0x0001
%define CS_HREDRAW 0x0002
%define CS_OWNDC   0x0020

%define WS_OVERLAPPEDWINDOW 0x00CF0000
%define WS_VISIBLE          0x10000000
%define CW_USEDEFAULT       0x80000000
%define SW_SHOW             5

%define WM_DESTROY 0x0002
%define WM_SIZE    0x0005
%define WM_CLOSE   0x0010
%define WM_QUIT    0x0012
%define WM_KEYDOWN 0x0100
%define WM_MOUSEMOVE    0x0200
%define WM_LBUTTONDOWN  0x0201
%define WM_LBUTTONUP    0x0202
%define WM_MOUSEWHEEL   0x020A
%define VK_ESCAPE  0x1B
%define VK_LEFT    0x25
%define VK_UP      0x26
%define VK_RIGHT   0x27
%define VK_DOWN    0x28
%define VK_C       0x43
%define VK_R       0x52

%define PM_REMOVE 1
%define IDC_ARROW 32512

%define PFD_DRAW_TO_WINDOW 0x00000004
%define PFD_SUPPORT_OPENGL 0x00000020
%define PFD_DOUBLEBUFFER   0x00000001
%define PFD_TYPE_RGBA      0
%define PFD_MAIN_PLANE     0

%define GENERIC_READ          0x80000000
%define FILE_SHARE_READ       0x00000001
%define OPEN_EXISTING         3
%define FILE_ATTRIBUTE_NORMAL 0x00000080
%define HEAP_ZERO_MEMORY      0x00000008
%define INVALID_HANDLE_VALUE  -1

%define MB_OK        0x00000000
%define MB_ICONERROR 0x00000010

%define GL_FALSE              0
%define GL_COLOR_BUFFER_BIT   0x00004000
%define GL_POINTS             0x0000
%define GL_VERTEX_SHADER      0x8B31
%define GL_FRAGMENT_SHADER    0x8B30
%define GL_GEOMETRY_SHADER    0x8DD9
%define GL_COMPILE_STATUS     0x8B81
%define GL_LINK_STATUS        0x8B82

extern GetModuleHandleA
extern LoadCursorA
extern RegisterClassExA
extern CreateWindowExA
extern ShowWindow
extern UpdateWindow
extern GetDC
extern GetClientRect
extern SetProcessDPIAware
extern DefWindowProcA
extern DestroyWindow
extern SetCapture
extern ReleaseCapture
extern PostQuitMessage
extern PeekMessageA
extern TranslateMessage
extern DispatchMessageA
extern MessageBoxA
extern ExitProcess
extern GetTickCount64
extern Sleep
extern LoadLibraryA
extern GetProcAddress

extern ChoosePixelFormat
extern SetPixelFormat
extern SwapBuffers

extern wglCreateContext
extern wglMakeCurrent
extern wglDeleteContext
extern wglGetProcAddress

extern CreateFileA
extern GetFileSize
extern ReadFile
extern CloseHandle
extern GetProcessHeap
extern HeapAlloc

extern glViewport
extern glClearColor
extern glClear

global main

section .data
class_name db 'WhiteHoleAsmWindow', 0
window_title db 'WhiteHole.asm - Schwarzschild white hole in Assembly + GLSL', 0

vertex_path db 'shaders/whitehole.vert', 0
geometry_path db 'shaders/whitehole.geom', 0
fragment_path db 'shaders/whitehole.frag', 0

err_title db 'WhiteHole.asm error', 0
err_register db 'RegisterClassExA failed.', 0
err_window db 'CreateWindowExA failed.', 0
err_dc db 'GetDC failed.', 0
err_pixel db 'OpenGL pixel format failed.', 0
err_context db 'OpenGL context creation failed.', 0
err_proc db 'Required OpenGL function missing.', 0
err_file db 'Could not read shader file.', 0
err_shader db 'Shader compilation failed.', 0
err_program db 'Program link failed.', 0
opengl32_dll db 'opengl32.dll', 0

proc_glCreateShader db 'glCreateShader', 0
proc_glShaderSource db 'glShaderSource', 0
proc_glCompileShader db 'glCompileShader', 0
proc_glGetShaderiv db 'glGetShaderiv', 0
proc_glGetShaderInfoLog db 'glGetShaderInfoLog', 0
proc_glCreateProgram db 'glCreateProgram', 0
proc_glAttachShader db 'glAttachShader', 0
proc_glLinkProgram db 'glLinkProgram', 0
proc_glGetProgramiv db 'glGetProgramiv', 0
proc_glGetProgramInfoLog db 'glGetProgramInfoLog', 0
proc_glUseProgram db 'glUseProgram', 0
proc_glGetUniformLocation db 'glGetUniformLocation', 0
proc_glUniform1f db 'glUniform1f', 0
proc_glUniform2f db 'glUniform2f', 0
proc_glDeleteShader db 'glDeleteShader', 0
proc_glGenVertexArrays db 'glGenVertexArrays', 0
proc_glBindVertexArray db 'glBindVertexArray', 0
proc_glDrawArrays db 'glDrawArrays', 0

uniform_time db 'u_time', 0
uniform_resolution db 'u_resolution', 0
uniform_camera_yaw db 'u_camera_yaw', 0
uniform_camera_pitch db 'u_camera_pitch', 0
uniform_camera_distance db 'u_camera_distance', 0
uniform_projection_center db 'u_projection_center', 0

f_zero dd 0.0
f_clear_r dd 0.003
f_clear_g dd 0.004
f_clear_b dd 0.010
f_one dd 1.0
f_1000 dd 1000.0
f_angle_scale dd 0.006
f_distance_base dd 13.5
f_distance_step dd 0.75
f_projection_scale dd 0.01

pfd:
    dw 40
    dw 1
    dd PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER
    db PFD_TYPE_RGBA
    db 32
    db 0, 0, 0, 0, 0, 0
    db 8, 0
    db 0
    db 0, 0, 0, 0
    db 24
    db 8
    db 0
    db PFD_MAIN_PLANE
    db 0
    dd 0
    dd 0
    dd 0

section .bss
wndclass resb 80
msgbuf resb 48
client_rect resb 16

hinstance resq 1
hwnd resq 1
hdc resq 1
hglrc resq 1
program_id resd 1
vertex_shader resd 1
geometry_shader resd 1
fragment_shader resd 1
vao_id resd 1
running resd 1
win_width resd 1
win_height resd 1
start_ms resq 1
time_float resd 1
shader_status resd 1
shader_source_ptr resq 1
bytes_read resd 1
shader_log resb 4096

loc_time resd 1
loc_resolution resd 1
loc_camera_yaw resd 1
loc_camera_pitch resd 1
loc_camera_distance resd 1
loc_projection_center resd 1
opengl32_module resq 1

mouse_down resd 1
last_mouse_x resd 1
last_mouse_y resd 1
camera_yaw_units resd 1
camera_pitch_units resd 1
camera_zoom_units resd 1
projection_x_units resd 1
projection_y_units resd 1

p_glCreateShader resq 1
p_glShaderSource resq 1
p_glCompileShader resq 1
p_glGetShaderiv resq 1
p_glGetShaderInfoLog resq 1
p_glCreateProgram resq 1
p_glAttachShader resq 1
p_glLinkProgram resq 1
p_glGetProgramiv resq 1
p_glGetProgramInfoLog resq 1
p_glUseProgram resq 1
p_glGetUniformLocation resq 1
p_glUniform1f resq 1
p_glUniform2f resq 1
p_glDeleteShader resq 1
p_glGenVertexArrays resq 1
p_glBindVertexArray resq 1
p_glDrawArrays resq 1

section .text

main:
    push rbp
    mov rbp, rsp
    sub rsp, 160

    mov dword [running], 1
    mov dword [win_width], 1280
    mov dword [win_height], 720
    mov dword [mouse_down], 0
    mov dword [camera_yaw_units], 0
    mov dword [camera_pitch_units], 16
    mov dword [camera_zoom_units], 0
    mov dword [projection_x_units], 0
    mov dword [projection_y_units], 0

    call SetProcessDPIAware

    xor ecx, ecx
    call GetModuleHandleA
    mov [hinstance], rax

    xor ecx, ecx
    mov edx, IDC_ARROW
    call LoadCursorA

    mov dword [wndclass + 0], 80
    mov dword [wndclass + 4], CS_HREDRAW | CS_VREDRAW | CS_OWNDC
    lea rdx, [WindowProc]
    mov [wndclass + 8], rdx
    mov dword [wndclass + 16], 0
    mov dword [wndclass + 20], 0
    mov rdx, [hinstance]
    mov [wndclass + 24], rdx
    mov qword [wndclass + 32], 0
    mov [wndclass + 40], rax
    mov qword [wndclass + 48], 0
    mov qword [wndclass + 56], 0
    lea rdx, [class_name]
    mov [wndclass + 64], rdx
    mov qword [wndclass + 72], 0

    lea rcx, [wndclass]
    call RegisterClassExA
    test rax, rax
    jnz .registered
    lea rcx, [err_register]
    call fatal_message

.registered:
    xor ecx, ecx
    lea rdx, [class_name]
    lea r8, [window_title]
    mov r9d, WS_OVERLAPPEDWINDOW | WS_VISIBLE
    mov dword [rsp + 32], CW_USEDEFAULT
    mov dword [rsp + 40], CW_USEDEFAULT
    mov qword [rsp + 48], 1280
    mov qword [rsp + 56], 720
    mov qword [rsp + 64], 0
    mov qword [rsp + 72], 0
    mov rax, [hinstance]
    mov [rsp + 80], rax
    mov qword [rsp + 88], 0
    call CreateWindowExA
    test rax, rax
    jnz .window_ok
    lea rcx, [err_window]
    call fatal_message

.window_ok:
    mov [hwnd], rax

    mov rcx, rax
    call GetDC
    test rax, rax
    jnz .dc_ok
    lea rcx, [err_dc]
    call fatal_message

.dc_ok:
    mov [hdc], rax

    mov rcx, rax
    lea rdx, [pfd]
    call ChoosePixelFormat
    test eax, eax
    jnz .pf_ok
    lea rcx, [err_pixel]
    call fatal_message

.pf_ok:
    mov rcx, [hdc]
    mov edx, eax
    lea r8, [pfd]
    call SetPixelFormat
    test eax, eax
    jnz .set_pf_ok
    lea rcx, [err_pixel]
    call fatal_message

.set_pf_ok:
    mov rcx, [hdc]
    call wglCreateContext
    test rax, rax
    jnz .ctx_created
    lea rcx, [err_context]
    call fatal_message

.ctx_created:
    mov [hglrc], rax
    mov rcx, [hdc]
    mov rdx, rax
    call wglMakeCurrent
    test eax, eax
    jnz .ctx_ok
    lea rcx, [err_context]
    call fatal_message

.ctx_ok:
    mov rcx, [hwnd]
    mov edx, SW_SHOW
    call ShowWindow
    mov rcx, [hwnd]
    call UpdateWindow

    call load_gl_functions
    call build_shader_program

    mov rcx, [program_id]
    call [p_glUseProgram]

    mov ecx, [program_id]
    lea rdx, [uniform_time]
    call [p_glGetUniformLocation]
    mov [loc_time], eax

    mov ecx, [program_id]
    lea rdx, [uniform_resolution]
    call [p_glGetUniformLocation]
    mov [loc_resolution], eax

    mov ecx, [program_id]
    lea rdx, [uniform_camera_yaw]
    call [p_glGetUniformLocation]
    mov [loc_camera_yaw], eax

    mov ecx, [program_id]
    lea rdx, [uniform_camera_pitch]
    call [p_glGetUniformLocation]
    mov [loc_camera_pitch], eax

    mov ecx, [program_id]
    lea rdx, [uniform_camera_distance]
    call [p_glGetUniformLocation]
    mov [loc_camera_distance], eax

    mov ecx, [program_id]
    lea rdx, [uniform_projection_center]
    call [p_glGetUniformLocation]
    mov [loc_projection_center], eax

    cmp qword [p_glGenVertexArrays], 0
    je .skip_vao
    mov ecx, 1
    lea rdx, [vao_id]
    call [p_glGenVertexArrays]
    mov ecx, [vao_id]
    call [p_glBindVertexArray]

.skip_vao:
    call GetTickCount64
    mov [start_ms], rax

.main_loop:
    cmp dword [running], 0
    je .shutdown

.pump_messages:
    lea rcx, [msgbuf]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    mov qword [rsp + 32], PM_REMOVE
    call PeekMessageA
    test eax, eax
    jz .render

    cmp dword [msgbuf + 8], WM_QUIT
    jne .dispatch
    mov dword [running], 0
    jmp .main_loop

.dispatch:
    lea rcx, [msgbuf]
    call TranslateMessage
    lea rcx, [msgbuf]
    call DispatchMessageA
    jmp .pump_messages

.render:
    call render_frame
    mov ecx, 1
    call Sleep
    jmp .main_loop

.shutdown:
    xor ecx, ecx
    xor edx, edx
    call wglMakeCurrent
    mov rcx, [hglrc]
    call wglDeleteContext
    xor ecx, ecx
    call ExitProcess

WindowProc:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    cmp edx, WM_SIZE
    jne .check_close
    mov eax, r9d
    and eax, 0FFFFh
    test eax, eax
    jnz .width_ok
    mov eax, 1
.width_ok:
    mov [win_width], eax
    mov eax, r9d
    shr eax, 16
    test eax, eax
    jnz .height_ok
    mov eax, 1
.height_ok:
    mov [win_height], eax
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.check_close:
    cmp edx, WM_CLOSE
    jne .check_destroy
    call DestroyWindow
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.check_destroy:
    cmp edx, WM_DESTROY
    jne .check_key
    xor ecx, ecx
    call PostQuitMessage
    mov dword [running], 0
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.check_key:
    cmp edx, WM_KEYDOWN
    jne .check_mouse_down
    cmp r8d, VK_ESCAPE
    jne .key_left
    call DestroyWindow
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.key_left:
    cmp r8d, VK_LEFT
    jne .key_right
    inc dword [projection_x_units]
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.key_right:
    cmp r8d, VK_RIGHT
    jne .key_up
    dec dword [projection_x_units]
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.key_up:
    cmp r8d, VK_UP
    jne .key_down
    dec dword [projection_y_units]
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.key_down:
    cmp r8d, VK_DOWN
    jne .key_center
    inc dword [projection_y_units]
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.key_center:
    cmp r8d, VK_C
    jne .key_reset
    mov dword [projection_x_units], 0
    mov dword [projection_y_units], 0
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.key_reset:
    cmp r8d, VK_R
    jne .default
    mov dword [camera_yaw_units], 0
    mov dword [camera_pitch_units], 16
    mov dword [camera_zoom_units], 0
    mov dword [projection_x_units], 0
    mov dword [projection_y_units], 0
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.check_mouse_down:
    cmp edx, WM_LBUTTONDOWN
    jne .check_mouse_up
    mov dword [mouse_down], 1
    mov eax, r9d
    movsx eax, ax
    mov [last_mouse_x], eax
    mov eax, r9d
    sar eax, 16
    mov [last_mouse_y], eax
    mov rcx, [hwnd]
    call SetCapture
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.check_mouse_up:
    cmp edx, WM_LBUTTONUP
    jne .check_mouse_move
    mov dword [mouse_down], 0
    call ReleaseCapture
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.check_mouse_move:
    cmp edx, WM_MOUSEMOVE
    jne .check_mouse_wheel
    cmp dword [mouse_down], 0
    je .default

    mov eax, r9d
    movsx r10d, ax
    mov eax, r9d
    sar eax, 16
    mov r11d, eax

    mov eax, r10d
    sub eax, [last_mouse_x]
    add [camera_yaw_units], eax

    mov eax, r11d
    sub eax, [last_mouse_y]
    sub [camera_pitch_units], eax

    mov eax, [camera_pitch_units]
    cmp eax, 240
    jle .pitch_high_ok
    mov dword [camera_pitch_units], 240
.pitch_high_ok:
    mov eax, [camera_pitch_units]
    cmp eax, -240
    jge .pitch_low_ok
    mov dword [camera_pitch_units], -240
.pitch_low_ok:
    mov [last_mouse_x], r10d
    mov [last_mouse_y], r11d
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.check_mouse_wheel:
    cmp edx, WM_MOUSEWHEEL
    jne .default
    mov eax, r8d
    sar eax, 16
    cmp eax, 0
    jg .wheel_in
    jl .wheel_out
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.wheel_in:
    dec dword [camera_zoom_units]
    mov eax, [camera_zoom_units]
    cmp eax, -10
    jge .wheel_done
    mov dword [camera_zoom_units], -10
    jmp .wheel_done

.wheel_out:
    inc dword [camera_zoom_units]
    mov eax, [camera_zoom_units]
    cmp eax, 32
    jle .wheel_done
    mov dword [camera_zoom_units], 32

.wheel_done:
    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.default:
    call DefWindowProcA
    add rsp, 48
    pop rbp
    ret

fatal_message:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov rdx, rcx
    xor ecx, ecx
    lea r8, [err_title]
    mov r9d, MB_OK | MB_ICONERROR
    call MessageBoxA
    mov ecx, 1
    call ExitProcess

load_one_proc:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 40
    mov rbx, rcx
    call wglGetProcAddress
    test rax, rax
    jz .fallback
    cmp rax, 1
    je .fallback
    cmp rax, 2
    je .fallback
    cmp rax, 3
    je .fallback
    cmp rax, -1
    je .fallback
    add rsp, 40
    pop rbx
    pop rbp
    ret
.fallback:
    cmp qword [opengl32_module], 0
    jne .have_module
    lea rcx, [opengl32_dll]
    call LoadLibraryA
    mov [opengl32_module], rax
.have_module:
    mov rcx, [opengl32_module]
    mov rdx, rbx
    call GetProcAddress
    test rax, rax
    jz .missing
    add rsp, 40
    pop rbx
    pop rbp
    ret
.missing:
    lea rcx, [err_proc]
    call fatal_message

load_gl_functions:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    lea rcx, [proc_glCreateShader]
    call load_one_proc
    mov [p_glCreateShader], rax
    lea rcx, [proc_glShaderSource]
    call load_one_proc
    mov [p_glShaderSource], rax
    lea rcx, [proc_glCompileShader]
    call load_one_proc
    mov [p_glCompileShader], rax
    lea rcx, [proc_glGetShaderiv]
    call load_one_proc
    mov [p_glGetShaderiv], rax
    lea rcx, [proc_glGetShaderInfoLog]
    call load_one_proc
    mov [p_glGetShaderInfoLog], rax
    lea rcx, [proc_glCreateProgram]
    call load_one_proc
    mov [p_glCreateProgram], rax
    lea rcx, [proc_glAttachShader]
    call load_one_proc
    mov [p_glAttachShader], rax
    lea rcx, [proc_glLinkProgram]
    call load_one_proc
    mov [p_glLinkProgram], rax
    lea rcx, [proc_glGetProgramiv]
    call load_one_proc
    mov [p_glGetProgramiv], rax
    lea rcx, [proc_glGetProgramInfoLog]
    call load_one_proc
    mov [p_glGetProgramInfoLog], rax
    lea rcx, [proc_glUseProgram]
    call load_one_proc
    mov [p_glUseProgram], rax
    lea rcx, [proc_glGetUniformLocation]
    call load_one_proc
    mov [p_glGetUniformLocation], rax
    lea rcx, [proc_glUniform1f]
    call load_one_proc
    mov [p_glUniform1f], rax
    lea rcx, [proc_glUniform2f]
    call load_one_proc
    mov [p_glUniform2f], rax
    lea rcx, [proc_glDeleteShader]
    call load_one_proc
    mov [p_glDeleteShader], rax
    lea rcx, [proc_glDrawArrays]
    call load_one_proc
    mov [p_glDrawArrays], rax

    lea rcx, [proc_glGenVertexArrays]
    call wglGetProcAddress
    mov [p_glGenVertexArrays], rax
    lea rcx, [proc_glBindVertexArray]
    call wglGetProcAddress
    mov [p_glBindVertexArray], rax

    add rsp, 32
    pop rbp
    ret

read_file:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    sub rsp, 88

    mov rdi, rcx
    mov rcx, rdi
    mov edx, GENERIC_READ
    mov r8d, FILE_SHARE_READ
    xor r9d, r9d
    mov qword [rsp + 32], OPEN_EXISTING
    mov qword [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0
    call CreateFileA
    cmp rax, INVALID_HANDLE_VALUE
    jne .opened
    xor eax, eax
    jmp .done

.opened:
    mov rbx, rax
    mov rcx, rbx
    xor edx, edx
    call GetFileSize
    test eax, eax
    jnz .size_ok
    mov rcx, rbx
    call CloseHandle
    xor eax, eax
    jmp .done

.size_ok:
    mov esi, eax
    call GetProcessHeap
    mov rcx, rax
    mov edx, HEAP_ZERO_MEMORY
    lea r8d, [rsi + 1]
    call HeapAlloc
    test rax, rax
    jnz .heap_ok
    mov rcx, rbx
    call CloseHandle
    xor eax, eax
    jmp .done

.heap_ok:
    mov rdi, rax
    mov rcx, rbx
    mov rdx, rdi
    mov r8d, esi
    lea r9, [bytes_read]
    mov qword [rsp + 32], 0
    call ReadFile
    test eax, eax
    jnz .read_ok
    mov rcx, rbx
    call CloseHandle
    xor eax, eax
    jmp .done

.read_ok:
    mov rcx, rbx
    call CloseHandle
    mov rax, rdi

.done:
    add rsp, 88
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret

compile_shader:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    sub rsp, 88

    mov esi, ecx
    mov rdi, rdx
    mov rcx, rdi
    call read_file
    test rax, rax
    jnz .source_ok
    lea rcx, [err_file]
    call fatal_message

.source_ok:
    mov [shader_source_ptr], rax
    mov ecx, esi
    call [p_glCreateShader]
    mov ebx, eax

    mov ecx, ebx
    mov edx, 1
    lea r8, [shader_source_ptr]
    xor r9d, r9d
    call [p_glShaderSource]

    mov ecx, ebx
    call [p_glCompileShader]

    mov ecx, ebx
    mov edx, GL_COMPILE_STATUS
    lea r8, [shader_status]
    call [p_glGetShaderiv]
    cmp dword [shader_status], GL_FALSE
    jne .compiled

    mov ecx, ebx
    mov edx, 4095
    lea r8, [bytes_read]
    lea r9, [shader_log]
    call [p_glGetShaderInfoLog]
    lea rcx, [shader_log]
    call fatal_shader_message

.compiled:
    mov eax, ebx
    add rsp, 88
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret

fatal_shader_message:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov rdx, rcx
    xor ecx, ecx
    lea r8, [err_shader]
    mov r9d, MB_OK | MB_ICONERROR
    call MessageBoxA
    mov ecx, 1
    call ExitProcess

build_shader_program:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    mov ecx, GL_VERTEX_SHADER
    lea rdx, [vertex_path]
    call compile_shader
    mov [vertex_shader], eax

    mov ecx, GL_GEOMETRY_SHADER
    lea rdx, [geometry_path]
    call compile_shader
    mov [geometry_shader], eax

    mov ecx, GL_FRAGMENT_SHADER
    lea rdx, [fragment_path]
    call compile_shader
    mov [fragment_shader], eax

    call [p_glCreateProgram]
    mov [program_id], eax

    mov ecx, eax
    mov edx, [vertex_shader]
    call [p_glAttachShader]
    mov ecx, [program_id]
    mov edx, [geometry_shader]
    call [p_glAttachShader]
    mov ecx, [program_id]
    mov edx, [fragment_shader]
    call [p_glAttachShader]

    mov ecx, [program_id]
    call [p_glLinkProgram]

    mov ecx, [program_id]
    mov edx, GL_LINK_STATUS
    lea r8, [shader_status]
    call [p_glGetProgramiv]
    cmp dword [shader_status], GL_FALSE
    jne .linked

    mov ecx, [program_id]
    mov edx, 4095
    lea r8, [bytes_read]
    lea r9, [shader_log]
    call [p_glGetProgramInfoLog]
    lea rcx, [shader_log]
    call fatal_program_message

.linked:
    mov ecx, [vertex_shader]
    call [p_glDeleteShader]
    mov ecx, [geometry_shader]
    call [p_glDeleteShader]
    mov ecx, [fragment_shader]
    call [p_glDeleteShader]

    add rsp, 48
    pop rbp
    ret

fatal_program_message:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov rdx, rcx
    xor ecx, ecx
    lea r8, [err_program]
    mov r9d, MB_OK | MB_ICONERROR
    call MessageBoxA
    mov ecx, 1
    call ExitProcess

render_frame:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    mov rcx, [hwnd]
    lea rdx, [client_rect]
    call GetClientRect
    mov eax, [client_rect + 8]
    sub eax, [client_rect + 0]
    test eax, eax
    jg .client_width_ok
    mov eax, 1
.client_width_ok:
    mov [win_width], eax
    mov eax, [client_rect + 12]
    sub eax, [client_rect + 4]
    test eax, eax
    jg .client_height_ok
    mov eax, 1
.client_height_ok:
    mov [win_height], eax

    xor ecx, ecx
    xor edx, edx
    mov r8d, [win_width]
    mov r9d, [win_height]
    call glViewport

    movss xmm0, [f_clear_r]
    movss xmm1, [f_clear_g]
    movss xmm2, [f_clear_b]
    movss xmm3, [f_one]
    call glClearColor

    mov ecx, GL_COLOR_BUFFER_BIT
    call glClear

    mov ecx, [program_id]
    call [p_glUseProgram]

    call GetTickCount64
    sub rax, [start_ms]
    cvtsi2ss xmm1, rax
    divss xmm1, [f_1000]
    movss [time_float], xmm1

    mov ecx, [loc_time]
    movss xmm1, [time_float]
    call [p_glUniform1f]

    cvtsi2ss xmm1, dword [win_width]
    cvtsi2ss xmm2, dword [win_height]
    mov ecx, [loc_resolution]
    call [p_glUniform2f]

    cvtsi2ss xmm1, dword [camera_yaw_units]
    mulss xmm1, [f_angle_scale]
    mov ecx, [loc_camera_yaw]
    call [p_glUniform1f]

    cvtsi2ss xmm1, dword [camera_pitch_units]
    mulss xmm1, [f_angle_scale]
    mov ecx, [loc_camera_pitch]
    call [p_glUniform1f]

    cvtsi2ss xmm1, dword [camera_zoom_units]
    mulss xmm1, [f_distance_step]
    addss xmm1, [f_distance_base]
    mov ecx, [loc_camera_distance]
    call [p_glUniform1f]

    cvtsi2ss xmm1, dword [projection_x_units]
    mulss xmm1, [f_projection_scale]
    cvtsi2ss xmm2, dword [projection_y_units]
    mulss xmm2, [f_projection_scale]
    mov ecx, [loc_projection_center]
    call [p_glUniform2f]

    xor ecx, ecx
    xor edx, edx
    mov r8d, 1
    call [p_glDrawArrays]

    mov rcx, [hdc]
    call SwapBuffers

    add rsp, 48
    pop rbp
    ret
