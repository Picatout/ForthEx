; constantes liées au générateur vidéo
    
.equ CHAR_WIDTH,  (8)
.equ CHAR_HEIGHT, (8)
.equ FONT_SIZE, (101)
.equ CPL, (50)  ; caractères pa ligne
.equ LPS, (24)  ; ligne par écran
;résolution d'image
.equ XRES, (CHAR_WIDTH*CPL)
.equ YRES, (CHAR_HEIGHT*LPS)
.equ TV_BUFFER, (CPL*LPS)
    