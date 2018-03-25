data segment
	inf db 40,40 dup(?)    ; 输入文件名
	outf db 40, 40 dup(?)  ; 输出文件名
	content1 db 4100 dup('$')    ; 发送缓冲区
	content2 db 4100 dup('$')    ; 接收缓冲区
	str1 db 'input file name:','$'
	str2 db 'output file name:','$'
	str3 db 'Press any key to start to send data',0dh,0ah,'$'
	str4 db 'Total transfering time(min:sec:persec):   ','$'
	err  db 'open file error',0dh,0ah,'$'
	crlf db 0dh,0ah,'$'          ; 换行
	inax dw 0       ; 输入文件标记
	outax dw 0      ; 输出文件标记
	min db 0
	sec db 0
	persec db 0
	words dw 0      ; 实际读到的字符数
data ends
code segment
     assume  cs:code,ds:data,es:data
  
start:
	mov dx,03fbh        ;准备设置com1除数寄存器
	mov al,80h
	out dx,al
	mov dx,03f8h        ;波特率4800
	mov al,18h          ;设置com1除数寄存器低位
	out dx,al
	mov dx,03f9h
	mov al,00h          ;设置com1除数寄存器高位
	out dx,al
	mov dx,03fbh       
	mov al,0eh          ;设置状态，7位数据位，2位停止位，奇校验
	out dx,al
	mov dx,03fch
	mov al,10h         ; loop位为1,自发自收
	out dx,al
	
	mov ax,data
	mov ds,ax
	
	lea dx,str1      ;得到输入文件名、路径
	mov ah,09h
	int 21h
	lea dx,inf
	mov ah,0ah
	int 21h
	lea dx,crlf
	mov ah,09h
	int 21h
	mov cl,inf+1
	mov ch,0         ;实际接受的字符串数
	mov si,cx
	mov inf[si+2],0  ;添加结束符
	lea dx,inf+2
	mov ah,3dh
	mov al,0
	int 21h
	mov inax,ax
	jc  errmsg
	lea dx,str2      ;得到输出文件名、路径
	mov ah,09h
	int 21h
	lea dx,outf
	mov ah,0ah
	int 21h
	lea dx,crlf
	mov ah,09h
	int 21h
	mov cl,outf+1
	mov ch,0         ;实际接受的字符串数
	mov si,cx
	mov outf[si+2],0 ;添加结束符
	mov ah,3ch      ;新建文件
	mov cx,00h
	lea dx,outf+2
	int 21h
	mov outax,ax
	jc  errmsg
	
	lea dx,str3       ;等待按键
	mov ah,09h
	int 21h
	mov ah,1
	int 21h
	
	mov ah,2ch     ;取时间
	int 21h	
	mov ah,2ch     ;取时间
	int 21h	
	mov sec,dh
	mov min,cl
	mov persec,dl
	
file:
	mov bx,inax         
	lea dx,content1      ; 读数据
	mov cx,4096
	mov ah,3fh
	int 21h
	jc errmsg
	
	mov words,ax     ; 实际读到的字符数
	cmp words,0
	jbe disp

	
	mov cx,words
	lea di,offset content1
	lea si,offset content2
send:
	mov dx,03fdh       ;判断com1线路状态寄存器发送寄存器是否为空
	in  al,dx          ;为空发送数据
	test al,20h   
	jz  send
	mov al,[di]
	mov dx,03f8h      ;发送数据
	out dx,al
	inc di	
	mov dx,03fdh       ;判断com1线路状态寄存器LSR接收数据是否就绪
	in  al,dx          ;就绪接收数据
	test al,01h        
	jz  send
	mov dx,03f8h
	in  al,dx
	mov [si],al        ;接收数据
	inc si
	loop send
	
wfile:
	mov bx,outax         
	lea dx,offset content2   ;输出数据
	mov cx,words
	mov ah,40h
	int 21h
	
	jmp file
	
disp:
		lea dx,str4    ;显示时间
	mov ah,09h
	int 21h
	mov ah,2ch     
    int 21h
	
	cmp persec,dl    ; 百分秒比较
	jbe next1
	add dl,100
	sub dh,1
next1:
	sub dl,persec  ; 秒比较
	mov persec,dl
	cmp sec,dh
	jbe next2
	add dh,60
	sub cl,1
next2:
	sub dh,sec      ; 分比较
	mov sec,dh
	cmp min,cl
	jbe next3
	add min,60

next3:
	sub cl,min    
	mov min,cl
	mov dl,min 
    push dx 
    call time    ;显示分 
    mov ah,02h
	mov dl,':'
	int 21h    
    mov dl,sec 
    call time    ;显示秒 
    mov ah,02h
	mov dl,':'
	int 21h 
	pop dx 
	mov dl,persec  
	call time    ;显示百分秒 
	mov dl,08h 
	mov ah,2h 
	int 21h 
	
	lea dx,crlf
	mov ah,09h
	int 21h
	
	mov ah,3eh    ; 关闭文件
	mov bx,inax
	int 21h
	mov ah,3eh
	mov bx,outax
	int 21h

exit:
     mov ax,4c00h
     int 21h          ;结束程序
	 
errmsg:
	lea dx,err      ;打开文件失败
	mov ah,09h
	int 21h
	jmp exit
	 
time proc           ;显示时间子程序 
	and dx,0ffh 
	mov ax,dx    ;被除数放在AX中,商在Al,余数在AH 
	mov bl,10d 
	div bl 
	mov bx,ax 
	add bh,30h 
	add bl,30h 
	mov dl,bl 
	mov ah,2h 
	int 21h 
	mov dl,bh 
	mov ah,2h 
	int 21h 
	ret 
time endp   

code ends
end  start
 