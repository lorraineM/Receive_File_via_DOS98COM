DATA_SEG segment
	infname	 db 40,40 dup (?)				;input file name
	outfname db 40,40 dup (?)				;output file name
	bufin	 db  4096 dup ('$') 			;50K input buffer
	bufout 	 db 4096 dup ('$') 			;50K output buffer
	str0	 db 'file input:','$'			;legend		
	str1	 db 'file output aim:','$'		;legend
	str2	 db 'Start send now?',0dh,0ah,'$'    ;legend
	totaltime db  'The total time is min:sec:persec: ', '$'
	filein	 dw 0                           ;file in
	fileout  dw 0 							;file out
	minute	 db 0 							;time minute
	second   db 0 							;time second
	totalw   dw 0 							;the total word you read
	crlf	 db 0dh,0ah,'$'	
	persec   db 0				;use for line feed
	error db 'EORROR!' ,0dh,0ah,'$'
DATA_SEG ends
CODE_SEG segment
assume cs:CODE_SEG,ds:DATA_SEG,es:DATA_SEG

main proc far

	;initialize
	mov dx,03fbh
	mov al,10001010b
	out dx,al
	mov dx,03f8h
	mov al,00011000b
	out dx,al
	inc dx
	mov al,0
	out dx,al
	mov dx,03fbh
	mov al,0eh
        out dx,al
	inc dx
	mov al,10h
	out dx,al

	mov ax,DATA_SEG
	mov ds,ax

	;sure the input file
	lea dx,str0
	mov ah,00001001b
	int 21h
	lea dx,infname
	mov ah,0ah
	int 21h
	lea dx,crlf
	mov ah,09h
	int 21h
	mov cl,infname+1
	mov ch,0
	mov si,cx
	mov infname[si+2],0
	lea dx,infname+2
	mov ah,3dh
	mov al,0
	int 21h
	mov filein,ax

	

	

	lea dx,str1
	mov ah,09h
	int 21h
	lea dx,outfname
	mov ah,0ah
	int 21h

	lea dx,crlf
	mov ah,09h
	int 21h
	mov cl,outfname+1
	mov ch,0
	mov si,cx
	mov outfname[si+2],0

            mov ah,3ch
	mov cx,0
	lea dx,outfname+2
	int 21h
	mov fileout,ax

	lea dx,str2
	mov ah,09h
	int 21h
	mov ah,1
	int 21h

	mov ah,2ch
	int 21h
	mov ah,2ch
	int 21h
	mov second,dh
	mov minute,cl
	mov persec,dl
read:
	mov bx,filein       
	lea dx,bufin      ; 读数�?	mov cx,4096
	mov cx,4096
	mov ah,3fh
	int 21h
	
	mov totalw,ax     ; 实际读到的字符数
	cmp totalw,0
	jbe disp

	mov cx,totalw
	lea di,bufin
	lea si,bufout

send:
	mov dx,03fdh       
	in  al,dx         
	test al,20h   
	jz  send
	mov al,[di]
	mov dx,03f8h      
	out dx,al
	inc di	
	mov dx,03fdh       
	in  al,dx         
	test al,01h        
	jz  send
	mov dx,03f8h
	in  al,dx
	mov [si],al        ;接收数据
	inc si
	loop send

write:
	mov bx,fileout      
	lea dx,bufout  
	mov cx,totalw
	mov ah,40h
	int 21h
	
	jmp read
	
disp:
	lea dx,totaltime
	mov ah,09h
	int 21h
	mov ah,2ch
	int 21h

	cmp persec,dl
	jbe T1
	add dl,100
	sub dh,1

T1:
	sub dl,persec
	mov persec,dl
	cmp second,dh
	jbe T2
	add dh,60
	sub cl,1
T2:
	sub dh,second
	mov second,dh
	cmp minute,cl
	jbe T3
	add minute,60

T3:
	sub cl,minute
	mov minute,cl
	mov dl,minute
	push dx
	call tcost
	mov ah,02h
	mov dl,':'
	int 21h
	mov dl,second
	call tcost
	mov ah,02h
	mov dl,':'
	int 21h
	pop dx
	mov dl,persec
	call tcost
	mov dl,08h
	mov ah,2h
	int 21h

	lea dx,crlf
	mov ah,09h
	int 21h

	mov ah,3eh    ; 关闭文件
	mov bx,filein
	int 21h
	mov ah,3eh
	mov bx,fileout
	int 21h
exit:
	mov ax,4c00h
	int 21h
ERRORMSG:
	lea dx,error      ;打开文件失败
	mov ah,09h
	int 21h
	jmp exit
tcost proc
	and dx,0ffh
	mov ax,dx
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
tcost endp
main endp	
CODE_SEG ends
end main