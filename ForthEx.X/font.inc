;****************************************************************************
; Copyright 2015,2016 Jacques Deschênes
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
; police de caractère 8x8
;table ASCII REF: http://www.asciitable.com/ 
    
/* 
 * File:   font.h
 * Author: jacques
 *
 * Created on 25 septembre 2015, 20:17
 */

#ifndef FONT_H
#define	FONT_H

#ifdef	__cplusplus
extern "C" {
#endif

#define CHAR_WIDTH  (8)
#define CHAR_HEIGHT (8)
#define FONT_SIZE (101)
#define CPL (40)  // caractères pa ligne
#define LPS (25)  // ligne par écran



#ifdef	__cplusplus
}
#endif

#endif	/* FONT_H */

