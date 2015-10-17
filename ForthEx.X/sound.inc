;****************************************************************************
; Copyright 2015, Jacques Deschênes
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

;Nom: sound.inc
;Description: constante utilisées pour la sortie tonalités audio.
;Date: 2015-10-16

.ifndef SOUND_INC
.equ SOUND_INC, 1
    
; gamme tempérée
; valeurs calculée pour Ftmr=2Mhz    
.equ DO1, 30577   ; 65,406
.equ DO1d, 28861  ; 69,29504076
.equ RE1, 27241	  ; 73,4153238836
.equ RE1d, 25712  ; 77,7805990417
.equ MI1, 24269	  ; 82,4054334607
.equ FA1, 22907	  ; 87,3052605343
.equ FA1d, 21621  ; 92,4964313257
.equ SOL1, 20407  ; 97,9962691323
.equ SOL1d, 19262 ; 103,8231272949
.equ LA1, 18181   ; 109,9964504439
.equ LA1d, 17160  ; 116,5368393873
.equ SI1, 16197	  ; 123,4661198572
.equ DO2, 15288	  ; 130,8074153439
.equ DO2d, 14430  ; 138,5852242603
.equ R2, 13620	  ; 146,8255016948
.equ R2d, 12856	  ; 155,5557460256
.equ MI2, 12134	  ; 164,8050906842
.equ FA2, 11453	  ; 174,6044013763
.equ FA2d, 10810  ; 184,9863790822
.equ SOL2, 10203  ; 195,9856691824
.equ SOL2d, 9631  ; 207,638977072
.equ LA2, 9090	  ; 219,9851906487
.equ LA2d, 8580	  ; 233,0655100846
.equ SI2, 8098	  ; 246,9235853143
.equ DO3, 7644	  ; 261,6056616971
.equ DO3d, 7215	  ; 277,1607343416
.equ RE3, 6810	  ; 293,6407116055
.equ R3d, 6427	  ; 311,1005883176
.equ MI3, 6066	  ; 329,598629299
.equ FA3, 5726	  ; 349,1965637971
.equ FA3d, 5404	  ; 369,9597914804
.equ SOL3, 5101	  ; 391,9576006819
.equ SOL3d, 4815  ; 415,2633996184
.equ LA3, 4544	  ; 439,9549613597
.equ LA3d, 4289	  ; 466,1146833622
.equ SI3, 4048	  ; 493,8298624349
.equ DO4, 3821	  ; 523,1929860553
.equ DO4d, 3607	  ; 554,3020410061
.equ RE4, 3404	  ; 587,2608403643
.equ R4d, 3213	  ; 622,1793699324
.equ MI4, 3033	  ; 659,1741552686
.equ FA4, 2862	  ; 698,3686505409
.equ FA4d, 2702	  ; 739,893650502
.equ SOL4, 2550	  ; 783,8877269609
.equ SOL4d, 2407  ; 830,497691206
.equ LA4, 2272	  ; 879,8790839251
.equ LA4d, 2144	  ; 932,1966942552
.equ SI4, 2024	  ; 987,6251096957
.equ DO5, 1910	  ; 1046,3492987182
.equ DO5d, 1803	  ; 1108,56522802
.equ RE5, 1701	  ; 1174,480516478
.equ RE5d, 1606	  ; 1244,3151279878
.equ MI5, 1516	  ; 1318,302105498
.equ FA5, 1430	  ; 1396,6883486909
.equ FA5d, 1350	  ; 1479,735437904
.equ SOL5, 1274	  ; 1567,7205070418
.equ SOL5d, 1203  ; 1660,9371683905
.equ LA5, 1135	  ; 1759,696492423
.equ LA5d, 1071	  ; 1864,3280458625
.equ SI5, 1011	  ; 1975,1809914695
.equ DO6, 954	  ; 2092,6252532222
.equ DO6d, 901	  ; 2217,0527507788
.equ RE6, 850	  ; 2348,8787073401
.equ RE6d, 802	  ; 2488,5430352786
.equ MI6, 757	  ; 2636,5118041562
.equ FA6, 715	  ; 2793,2787960314
.equ FA6d, 674	  ; 2959,3671532434
.equ SOL6, 636	  ; 3135,3311241752
.equ SOL6d, 601	  ; 3321,7579128187
.equ LA6, 567	  ; 3519,2696383149
.equ LA6d, 535	  ; 3728,5254110091
.equ SI6, 505	  ; 3950,2235319477
.equ DO7, 476	  ; 4185,1038231573
.equ DO7d, 450	  ; 4433,9500964822
.equ RE7, 424	  ; 4697,5927692191
.equ RE7d, 400	  ; 4976,9116352768
    
.endif
 