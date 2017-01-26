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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; bits de configuration du MCU
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "p24EP512GP202.inc"

    config __FICD, JTAGEN_OFF
    config __FPOR, 0xFFFF
    config __FWDT, FWDTEN_OFF & WINDIS_OFF & PLLKEN_OFF
    config __FOSC, FCKSM_CSDCMD & POSCMD_HS & OSCIOFNC_ON  & IOL1WAY_OFF
    config __FOSCSEL, FNOSC_PRIPLL & IESO_ON
    config __FGS, 0xFFFF
    
   

.end
