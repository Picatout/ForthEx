;****************************************************************************
; Copyright 2015,2016,2017 Jacques Deschenes
; This file is part of ForthEx.
;
;     ForthEx is free software: you can redistribute it and/or modify
;     it under the terms of the GNU General Public License as published by
;     the Free Software Foundation, either version 3 of the License, or
;     (at your option) any later version.
;
;     ForthEx is distributed in the hope that it will be useful,
;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;     GNU General Public License for more details.
;
;     You should have received a copy of the GNU General Public License
;     along with ForthEx.  If not, see <http://www.gnu.org/licenses/>.
;
;****************************************************************************
;
; police de caract�re 6x8
;table ASCII REF: http://www.asciitable.com/ 
    
;#include "video.inc"
    
.section .font.const psv
.global _font
_font:
.byte 0xFC,0x84,0x84,0x84,0x84,0x84,0x84,0xFC  ; 0 vide
.byte 0x00,0x00,0x00,0x0F,0x08,0x08,0x08,0x08  ; 1 coin haut-gauche
.byte 0x08,0x08,0x08,0x0F,0x00,0x00,0x00,0x00  ; 2 coin bas-gauche
.byte 0x00,0x00,0x00,0xF8,0x08,0x08,0x08,0x08  ; 3 coin haut-droite
.byte 0x08,0x08,0x08,0xF8,0x00,0x00,0x00,0x00  ; 4 coin bas-droite
.byte 0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08  ; 5 verticale
.byte 0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0x00  ; 6 horizontale    
.byte 0x08,0x08,0x08,0xFF,0x08,0x08,0x08,0x08  ; 7 croix
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00  ; 8 r�serv� BACK
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00  ; 9 r�serv� tabulation
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00  ; 10 r�server CRLF
.byte 0x00,0x00,0x00,0xFF,0x08,0x08,0x08,0x08  ; 11 T barre 			
.byte 0x08,0x08,0x08,0xFF,0x00,0x00,0x00,0x00  ; 12 T barre renvers�
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00  ; 13 r�serv� CRLF    
.byte 0x08,0x08,0x08,0x0F,0x08,0x08,0x08,0x08  ; 14 T barre rotation gauche
.byte 0x08,0x08,0x08,0xF8,0x08,0x08,0x08,0x08  ; 15 T barre rotation droite
.byte 0x80,0xC0,0xE0,0xF0,0xE0,0xC0,0x80,0x00  ; 16 triangle droite
.byte 0x01,0x03,0x07,0x0F,0x07,0x03,0x01,0x00  ; 17 triangle gauche
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00  ; 18 fl�che haut/bas
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00  ; 19 double exclamation
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00  ; 20 p miroir
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00  ; 21 s-rond
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFE  ; 22 soulignement
.byte 0x10,0x38,0x7C,0x10,0x10,0x10,0x00,0xFE  ; 23 fl�che haut/bas soulign�e
.byte 0x20,0x70,0xA8,0x20,0x20,0x20,0x00,0x00  ; 24 fl�che haut
.byte 0x00,0x20,0x20,0x20,0xA8,0x70,0x20,0x00  ; 25 fl�che bas
.byte 0x40,0x20,0x10,0xF8,0x10,0x20,0x40,0x00  ; 26 f�che droite
.byte 0x10,0x20,0x40,0xF8,0x40,0x20,0x10,0x00  ; 27 f�che gauche
.byte 0x00,0x00,0x00,0x80,0x80,0x80,0xFE,0x00  ; 28 �querre
.byte 0x00,0x00,0x44,0xFE,0x44,0x00,0x00,0x00  ; 29 fl�che gauche/droite
.byte 0x00,0x00,0x10,0x38,0x7C,0xFE,0x00,0x00  ; 30 triangle haut
.byte 0x00,0x00,0xFE,0x7C,0x38,0x10,0x00,0x00  ; 31 triangle bas
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00  ; 32 espace
.byte 0x20,0x20,0x20,0x20,0x20,0x00,0x20,0x00  ; 33 !
.byte 0x50,0x50,0x50,0x00,0x00,0x00,0x00,0x00  ; 34 "
.byte 0x50,0x50,0xF8,0x50,0xF8,0x50,0x50,0x00  ; 35 #
.byte 0x20,0x78,0xA0,0x70,0x28,0xF0,0x20,0x00  ; 36 $
.byte 0xC0,0xC8,0x10,0x20,0x40,0x98,0x18,0x00  ; 37 %
.byte 0x60,0x90,0xA0,0x40,0xA8,0x90,0x68,0x00  ; 38 &
.byte 0x60,0x20,0x40,0x00,0x00,0x00,0x00,0x00  ; 39 '
.byte 0x10,0x20,0x40,0x40,0x40,0x20,0x10,0x00  ; 40 (
.byte 0x40,0x20,0x10,0x10,0x10,0x20,0x40,0x00  ; 41 )
.byte 0x00,0x20,0xA8,0x70,0xA8,0x20,0x00,0x00  ; 42 *
.byte 0x00,0x20,0x20,0xF8,0x20,0x20,0x00,0x00  ; 43 +
.byte 0x00,0x00,0x00,0x00,0x60,0x20,0x40,0x00  ; 44 ,
.byte 0x00,0x00,0x00,0xF0,0x00,0x00,0x00,0x00  ; 45 -
.byte 0x00,0x00,0x00,0x00,0x00,0x60,0x60,0x00  ; 46 .
.byte 0x00,0x08,0x10,0x20,0x40,0x80,0x00,0x00  ; 47 /
.byte 0x70,0x88,0x98,0xA8,0xC8,0x88,0x70,0x00  ; 48 0
.byte 0x20,0x60,0x20,0x20,0x20,0x20,0xF8,0x00  ; 49 1
.byte 0x70,0x88,0x10,0x20,0x40,0x80,0xF8,0x00  ; 50 2
.byte 0xF0,0x08,0x08,0xF0,0x08,0x08,0xF0,0x00  ; 51 3
.byte 0x10,0x30,0x50,0x90,0xF8,0x10,0x10,0x00  ; 52 4
.byte 0xF8,0x80,0x80,0xF0,0x08,0x08,0xF0,0x00  ; 53 5
.byte 0x30,0x40,0x80,0xF0,0x88,0x88,0x70,0x00  ; 54 6
.byte 0xF8,0x08,0x10,0x20,0x40,0x40,0x40,0x00  ; 55 7
.byte 0x70,0x88,0x88,0x70,0x88,0x88,0x70,0x00  ; 56 8
.byte 0x70,0x88,0x88,0x70,0x08,0x08,0x70,0x00  ; 57 9
.byte 0x00,0x60,0x60,0x00,0x60,0x60,0x00,0x00  ; 58 :
.byte 0x00,0x60,0x60,0x00,0x60,0x20,0x40,0x00  ; 59 ;
.byte 0x10,0x20,0x40,0x80,0x40,0x20,0x10,0x00  ; 60 <
.byte 0x00,0x00,0xF8,0x00,0xF8,0x00,0x00,0x00  ; 61 =
.byte 0x40,0x20,0x10,0x08,0x10,0x20,0x40,0x00  ; 62 >
.byte 0x70,0x88,0x08,0x10,0x20,0x00,0x20,0x00  ; 63 ?
.byte 0x70,0x88,0x08,0x68,0xA8,0xA8,0x70,0x00  ; 64 @
.byte 0x70,0x88,0x88,0xF8,0x88,0x88,0x88,0x00  ; 65 A
.byte 0xF0,0x88,0x88,0xF0,0x88,0x88,0xF0,0x00  ; 66 B
.byte 0x78,0x80,0x80,0x80,0x80,0x80,0x78,0x00  ; 67 C
.byte 0xF0,0x88,0x88,0x88,0x88,0x88,0xF0,0x00  ; 68 D
.byte 0xF8,0x80,0x80,0xF8,0x80,0x80,0xF8,0x00  ; 69 E
.byte 0xF8,0x80,0x80,0xF8,0x80,0x80,0x80,0x00  ; 70 F
.byte 0x78,0x80,0x80,0xB0,0x88,0x88,0x70,0x00  ; 71 G
.byte 0x88,0x88,0x88,0xF8,0x88,0x88,0x88,0x00  ; 72 H
.byte 0x70,0x20,0x20,0x20,0x20,0x20,0x70,0x00  ; 73 I
.byte 0x78,0x08,0x08,0x08,0x08,0x90,0x60,0x00  ; 74 J
.byte 0x88,0x90,0xA0,0xC0,0xA0,0x90,0x88,0x00  ; 75 K
.byte 0x80,0x80,0x80,0x80,0x80,0x80,0xF8,0x00  ; 76 L
.byte 0x88,0xD8,0xA8,0x88,0x88,0x88,0x88,0x00  ; 77 M
.byte 0x88,0x88,0xC8,0xA8,0x98,0x88,0x88,0x00  ; 78 N
.byte 0x70,0x88,0x88,0x88,0x88,0x88,0x70,0x00  ; 79 O
.byte 0xF0,0x88,0x88,0xF0,0x80,0x80,0x80,0x00  ; 80 P
.byte 0x70,0x88,0x88,0x88,0xA8,0x98,0x78,0x00  ; 81 Q
.byte 0xF0,0x88,0x88,0xF0,0xA0,0x90,0x88,0x00  ; 82 R
.byte 0x78,0x80,0x80,0x70,0x08,0x08,0xF0,0x00  ; 83 S
.byte 0xF8,0x20,0x20,0x20,0x20,0x20,0x20,0x00  ; 84 T
.byte 0x88,0x88,0x88,0x88,0x88,0x88,0x70,0x00  ; 85 U
.byte 0x88,0x88,0x88,0x88,0x88,0x50,0x20,0x00  ; 86 V
.byte 0x88,0x88,0x88,0xA8,0xA8,0xD8,0x88,0x00  ; 87 W
.byte 0x88,0x88,0x50,0x20,0x50,0x88,0x88,0x00  ; 88 X
.byte 0x88,0x88,0x88,0x50,0x20,0x20,0x20,0x00  ; 89 Y
.byte 0xF8,0x10,0x20,0x40,0x80,0x80,0xF8,0x00  ; 90 Z
.byte 0x70,0x40,0x40,0x40,0x40,0x40,0x70,0x00  ; 91 [
.byte 0x00,0x80,0x40,0x20,0x10,0x08,0x00,0x00  ; 92 '\'
.byte 0x38,0x08,0x08,0x08,0x08,0x08,0x38,0x00  ; 93 ]
.byte 0x20,0x50,0x88,0x00,0x00,0x00,0x00,0x00  ; 94 ^
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xF8  ; 95 _
.byte 0x40,0x20,0x10,0x00,0x00,0x00,0x00,0x00  ; 96 `
.byte 0x00,0x00,0x70,0x08,0x78,0x88,0x78,0x00  ; 97 a
.byte 0x80,0x80,0x80,0xB0,0xC8,0x88,0xF0,0x00  ; 98 b
.byte 0x00,0x00,0x70,0x80,0x80,0x88,0x70,0x00  ; 99 c
.byte 0x08,0x08,0x08,0x68,0x98,0x88,0x78,0x00  ; 100 d
.byte 0x00,0x00,0x70,0x88,0xF8,0x80,0x70,0x00  ; 101 e
.byte 0x30,0x48,0x40,0xE0,0x40,0x40,0x40,0x00  ; 102 f
.byte 0x00,0x00,0x78,0x88,0x88,0x78,0x08,0x70  ; 103 g
.byte 0x80,0x80,0xB0,0xC8,0x88,0x88,0x88,0x00  ; 104 h
.byte 0x00,0x20,0x00,0x20,0x20,0x20,0x20,0x00  ; 105 i
.byte 0x10,0x00,0x30,0x10,0x10,0x90,0x60,0x00  ; 106 j
.byte 0x80,0x80,0x90,0xA0,0xC0,0xA0,0x90,0x00  ; 107 k
.byte 0x60,0x20,0x20,0x20,0x20,0x20,0x70,0x00  ; 108 l
.byte 0x00,0x00,0xD0,0xA8,0xA8,0x88,0x88,0x00  ; 109 m
.byte 0x00,0x00,0xB0,0xC8,0x88,0x88,0x88,0x00  ; 110 n
.byte 0x00,0x00,0x70,0x88,0x88,0x88,0x70,0x00  ; 111 o
.byte 0x00,0x00,0xF0,0x88,0x88,0xF0,0x80,0x80  ; 112 p
.byte 0x00,0x00,0x68,0x90,0x90,0xB0,0x50,0x18  ; 113 q
.byte 0x00,0x00,0xB0,0xC8,0x80,0x80,0x80,0x00  ; 114 r
.byte 0x00,0x00,0x70,0x80,0x70,0x08,0xF0,0x00  ; 115 s
.byte 0x40,0x40,0xE0,0x40,0x40,0x48,0x30,0x00  ; 116 t
.byte 0x00,0x00,0x88,0x88,0x88,0x98,0x68,0x00  ; 117 u
.byte 0x00,0x00,0x88,0x88,0x88,0x50,0x20,0x00  ; 118 v
.byte 0x00,0x00,0x88,0x88,0xA8,0xA8,0x50,0x00  ; 119 w
.byte 0x00,0x00,0x88,0x50,0x20,0x50,0x88,0x00  ; 120 x
.byte 0x00,0x00,0x88,0x88,0x88,0x78,0x08,0x70  ; 121 y
.byte 0x00,0x00,0xF8,0x10,0x20,0x40,0xF8,0x00  ; 122 z
.byte 0x20,0x40,0x40,0x80,0x40,0x40,0x20,0x00  ; 123 {
.byte 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x00  ; 124 |
.byte 0x40,0x20,0x20,0x10,0x20,0x20,0x40,0x00  ; 125 }
.byte 0x00,0x00,0x40,0xA8,0x10,0x00,0x00,0x00  ; 126 ~
.byte 0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,0xFC  ; 127 rectangle
