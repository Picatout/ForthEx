;****************************************************************************
; Copyright 2015,2016,2017 Jacques Deschênes
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
; NOM: eds.s
; DATE: 2017-05-21
; DESCRIPTION: 
;   Certains PIC24 et dsPIC33 possèdent de la mémoire RAM au-delà de l'adresse
;   32767 (0x7FFF) Microchip appelle cette mémoire EDS (Extended Data Space).
;   Cette plage d'adresse entre en conflit avec la plage d'adresse PSV (Progam Visibility Space).
;   Il y a donc un mécanisme qui permet de différiencier ces 2 plages en utilisant
;   les registres DSRPAG et DSWPAG.  Puisque la machine virtuelle de ForthEx fonctionne
;   en lisant des listes d'adresses aussi bien en RAM qu'en FLASH le registre DSRPAG
;   qui détermine qu'elle plage sera accédée en lecture est configuré par défaut pour
;   acccédé la plage {0..32766} de la mémoire FLASH là où réside le système Forth.
;   Cependant il doit-existé un mécanisme pour lire la mémoire EDS. Ce mécanisme
;   est constitué d'une série de mots spéciaux qui accèdent cette mémoire en lecture.
;       
;   Pour l'accès en écriture ForthEx est configurée par défaut pour accéder la mémoire
;   EDS puisque de toute façon on ne peut écrire en mémoire FLASH. Il n'est donc pas
;   nécessaire d'avoir de mots spéciaux pour l'écriture dans la mémoire EDS.
    
; nom: E@  ( a-addr -- n )    
;   Retourne l'entier contenu à l'adresse a-addr. 
;   L'adresse doit-être alignée sur un nombre pair.    
;   Les adresses > 32767 accèdent la mémoire EDS.
; arguments:
;   a-addr  Adresse à lire.
; retourne:
;   n	Entier contenu à cette adresse.    
DEFCODE "E@",2,,EFETCH ; ( addr -- n )
    SET_EDS
    mov [T],T
    RESET_EDS
    NEXT
    
; nom: EC@  ( c-addr -- c )    
;   Retourne le caractère contenu à l'adressse c-addr.
;   Cette adresse est alignée sur un octet.    
;   Les adresses > 32767 accès la mémoire EDS.    
; arguments:
;   c-addr   Adresse à lire.
; retourne:
;   c	Caractère contenu à cette adresse.    
DEFCODE "EC@",3,,ECFETCH 
    SET_EDS
    mov.b [T],T
    ze T,T
    RESET_EDS
    NEXT

; nom: ETBL@  ( n a-addr -- n )
;   Retourne l'élément n d'un vecteur. Les valeurs d'indice débute à zéro.
;   L'adresse de la table doit-être alignée sur une adresse paire.
;   Les adresses > 32767 sont en mémoire EDS.    
; arguments:
;   n  Indice dans le vecteur.
;   a-addr  Adresse du vecteur.
; retourne:
;   n    Valeur de l'élément n du vecteur.    
DEFCODE "ETBL@",5,,ETBLFETCH
    SET_EDS
    mov [DSP--],W0
    mov #CELL_SIZE,W1
    mul.uu W1,W0,W0
    add T,W0,W0
    mov [W0],T
    RESET_EDS
    NEXT


