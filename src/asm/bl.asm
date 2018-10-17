00007C00  EB58              jmp short 0x7c5a
00007C02  90                nop
00007C03  4D                dec bp
00007C04  53                push bx
00007C05  44                inc sp
00007C06  4F                dec di
00007C07  53                push bx
00007C08  352E30            xor ax,0x302e
00007C0B  0002              add [bp+si],al
00007C0D  40                inc ax
00007C0E  60                pusha
00007C0F  0202              add al,[bp+si]
00007C11  0000              add [bx+si],al
00007C13  0000              add [bx+si],al
00007C15  F8                clc
00007C16  0000              add [bx+si],al
00007C18  3F                aas
00007C19  00800080          add [bx+si-0x8000],al
00007C1D  1F                pop ds
00007C1E  0000              add [bx+si],al
00007C20  80A0DD01F0        and byte [bx+si+0x1dd],0xf0
00007C25  0E                push cs
00007C26  0000              add [bx+si],al
00007C28  0000              add [bx+si],al
00007C2A  0000              add [bx+si],al
00007C2C  0200              add al,[bx+si]
00007C2E  0000              add [bx+si],al
00007C30  0100              add [bx+si],ax
00007C32  0800              or [bx+si],al
00007C34  50                push ax
00007C35  684973            push word 0x7349
00007C38  4F                dec di
00007C39  6E                outsb
00007C3A  0000              add [bx+si],al
00007C3C  0000              add [bx+si],al
00007C3E  0000              add [bx+si],al
00007C40  0001              add [bx+di],al
00007C42  29E5              sub bp,sp
00007C44  3C9B              cmp al,0x9b
00007C46  D7                xlatb
00007C47  647269            fs jc 0x7cb3
00007C4A  7665              jna 0x7cb1
00007C4C  2020              and [bx+si],ah
00007C4E  2020              and [bx+si],ah
00007C50  2020              and [bx+si],ah
00007C52  46                inc si
00007C53  41                inc cx
00007C54  54                push sp
00007C55  3332              xor si,[bp+si]
00007C57  2020              and [bx+si],ah
00007C59  2033              and [bp+di],dh
00007C5B  C9                leave
00007C5C  8ED1              mov ss,cx
00007C5E  BCF47B            mov sp,0x7bf4
00007C61  8EC1              mov es,cx
00007C63  8ED9              mov ds,cx
00007C65  BD007C            mov bp,0x7c00
00007C68  884E02            mov [bp+0x2],cl
00007C6B  8A5640            mov dl,[bp+0x40]
00007C6E  B408              mov ah,0x8
00007C70  CD13              int 0x13
00007C72  7305              jnc 0x7c79
00007C74  B9FFFF            mov cx,0xffff
00007C77  8AF1              mov dh,cl
00007C79  660FB6C6          movzx eax,dh
00007C7D  40                inc ax
00007C7E  660FB6D1          movzx edx,cl
00007C82  80E23F            and dl,0x3f
00007C85  F7E2              mul dx
00007C87  86CD              xchg cl,ch
00007C89  C0ED06            shr ch,byte 0x6
00007C8C  41                inc cx
00007C8D  660FB7C9          movzx ecx,cx
00007C91  66F7E1            mul ecx
00007C94  668946F8          mov [bp-0x8],eax
00007C98  837E1600          cmp word [bp+0x16],byte +0x0
00007C9C  7538              jnz 0x7cd6
00007C9E  837E2A00          cmp word [bp+0x2a],byte +0x0
00007CA2  7732              ja 0x7cd6
00007CA4  668B461C          mov eax,[bp+0x1c]
00007CA8  6683C00C          add eax,byte +0xc
00007CAC  BB0080            mov bx,0x8000
00007CAF  B90100            mov cx,0x1
00007CB2  E82B00            call 0x7ce0
00007CB5  E94803            jmp 0x8000
00007CB8  A0FA7D            mov al,[0x7dfa]
00007CBB  B47D              mov ah,0x7d
00007CBD  8BF0              mov si,ax
00007CBF  AC                lodsb
00007CC0  84C0              test al,al
00007CC2  7417              jz 0x7cdb
00007CC4  3CFF              cmp al,0xff
00007CC6  7409              jz 0x7cd1
00007CC8  B40E              mov ah,0xe
00007CCA  BB0700            mov bx,0x7
00007CCD  CD10              int 0x10
00007CCF  EBEE              jmp short 0x7cbf
00007CD1  A0FB7D            mov al,[0x7dfb]
00007CD4  EBE5              jmp short 0x7cbb
00007CD6  A0F97D            mov al,[0x7df9]
00007CD9  EBE0              jmp short 0x7cbb
00007CDB  98                cbw
00007CDC  CD16              int 0x16
00007CDE  CD19              int 0x19
00007CE0  6660              pushad
00007CE2  663B46F8          cmp eax,[bp-0x8]
00007CE6  0F824A00          jc near 0x7d34
00007CEA  666A00            o32 push byte +0x0
00007CED  6650              push eax
00007CEF  06                push es
00007CF0  53                push bx
00007CF1  666810000100      push dword 0x10010
00007CF7  807E0200          cmp byte [bp+0x2],0x0
00007CFB  0F852000          jnz near 0x7d1f
00007CFF  B441              mov ah,0x41
00007D01  BBAA55            mov bx,0x55aa
00007D04  8A5640            mov dl,[bp+0x40]
00007D07  CD13              int 0x13
00007D09  0F821C00          jc near 0x7d29
00007D0D  81FB55AA          cmp bx,0xaa55
00007D11  0F851400          jnz near 0x7d29
00007D15  F6C101            test cl,0x1
00007D18  0F840D00          jz near 0x7d29
00007D1C  FE4602            inc byte [bp+0x2]
00007D1F  B442              mov ah,0x42
00007D21  8A5640            mov dl,[bp+0x40]
00007D24  8BF4              mov si,sp
00007D26  CD13              int 0x13
00007D28  B0F9              mov al,0xf9
00007D2A  6658              pop eax
00007D2C  6658              pop eax
00007D2E  6658              pop eax
00007D30  6658              pop eax
00007D32  EB2A              jmp short 0x7d5e
00007D34  6633D2            xor edx,edx
00007D37  660FB74E18        movzx ecx,word [bp+0x18]
00007D3C  66F7F1            div ecx
00007D3F  FEC2              inc dl
00007D41  8ACA              mov cl,dl
00007D43  668BD0            mov edx,eax
00007D46  66C1EA10          shr edx,byte 0x10
00007D4A  F7761A            div word [bp+0x1a]
00007D4D  86D6              xchg dl,dh
00007D4F  8A5640            mov dl,[bp+0x40]
00007D52  8AE8              mov ch,al
00007D54  C0E406            shl ah,byte 0x6
00007D57  0ACC              or cl,ah
00007D59  B80102            mov ax,0x201
00007D5C  CD13              int 0x13
00007D5E  6661              popad
00007D60  0F8254FF          jc near 0x7cb8
00007D64  81C30002          add bx,0x200
00007D68  6640              inc eax
00007D6A  49                dec cx
00007D6B  0F8571FF          jnz near 0x7ce0
00007D6F  C3                ret
00007D70  4E                dec si
00007D71  54                push sp
00007D72  4C                dec sp
00007D73  44                inc sp
00007D74  52                push dx
00007D75  2020              and [bx+si],ah
00007D77  2020              and [bx+si],ah
00007D79  2020              and [bx+si],ah
00007D7B  0000              add [bx+si],al
00007D7D  0000              add [bx+si],al
00007D7F  0000              add [bx+si],al
00007D81  0000              add [bx+si],al
00007D83  0000              add [bx+si],al
00007D85  0000              add [bx+si],al
00007D87  0000              add [bx+si],al
00007D89  0000              add [bx+si],al
00007D8B  0000              add [bx+si],al
00007D8D  0000              add [bx+si],al
00007D8F  0000              add [bx+si],al
00007D91  0000              add [bx+si],al
00007D93  0000              add [bx+si],al
00007D95  0000              add [bx+si],al
00007D97  0000              add [bx+si],al
00007D99  0000              add [bx+si],al
00007D9B  0000              add [bx+si],al
00007D9D  0000              add [bx+si],al
00007D9F  0000              add [bx+si],al
00007DA1  0000              add [bx+si],al
00007DA3  0000              add [bx+si],al
00007DA5  0000              add [bx+si],al
00007DA7  0000              add [bx+si],al
00007DA9  0000              add [bx+si],al
00007DAB  000D              add [di],cl
00007DAD  0A5265            or dl,[bp+si+0x65]
00007DB0  6D                insw
00007DB1  6F                outsw
00007DB2  7665              jna 0x7e19
00007DB4  206469            and [si+0x69],ah
00007DB7  736B              jnc 0x7e24
00007DB9  7320              jnc 0x7ddb
00007DBB  6F                outsw
00007DBC  7220              jc 0x7dde
00007DBE  6F                outsw
00007DBF  7468              jz 0x7e29
00007DC1  657220            gs jc 0x7de4
00007DC4  6D                insw
00007DC5  656469612EFF0D    imul sp,[fs:bx+di+0x2e],word 0xdff
00007DCC  0A4469            or al,[si+0x69]
00007DCF  736B              jnc 0x7e3c
00007DD1  206572            and [di+0x72],ah
00007DD4  726F              jc 0x7e45
00007DD6  72FF              jc 0x7dd7
00007DD8  0D0A50            or ax,0x500a
00007DDB  7265              jc 0x7e42
00007DDD  7373              jnc 0x7e52
00007DDF  20616E            and [bx+di+0x6e],ah
00007DE2  7920              jns 0x7e04
00007DE4  6B657920          imul sp,[di+0x79],byte +0x20
00007DE8  746F              jz 0x7e59
00007DEA  207265            and [bp+si+0x65],dh
00007DED  7374              jnc 0x7e63
00007DEF  61                popa
00007DF0  7274              jc 0x7e66
00007DF2  0D0A00            or ax,0xa
00007DF5  0000              add [bx+si],al
00007DF7  0000              add [bx+si],al
00007DF9  AC                lodsb
00007DFA  CB                retf
00007DFB  D800              fadd dword [bx+si]
00007DFD  0055AA            add [di-0x56],dl
