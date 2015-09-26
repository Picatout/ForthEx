
;résolution d'image
.equ XRES, 320
.equ YRES, 200
.equ BPL, (XRES/8)
.equ ROW, (YRES/8)
.equ TV_BUFFER, (ROW*BPL)


; constantes génération signal NTSC
.equ HFREQ, 15748 ; fréquence horizontale pour information seulement
.equ HLINE, 1015 ; PR2= période ligne horizontale
.equ HSYNC, 74  ; OC1R=47e-6*FCY-1 sync pulse horizontal
.equ HALFLINE, 507 ; période demi-ligne horizontale (VSYNC)
.equ SERATION, (HSYNC/2) ;durée pulse dans VSYNC
.equ TOPLINE, 40  ; première ligne visible





