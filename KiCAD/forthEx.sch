EESchema Schematic File Version 2
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:special
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:forthEx-cache
EELAYER 25 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date "12 sep 2015"
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L PIC24FJ64GA002 U2
U 1 1 5577231C
P 5600 3750
F 0 "U2" H 5600 3000 60  0000 C CNN
F 1 "PIC24FJ64GA002" H 5600 4650 60  0000 C CNN
F 2 "" H 5600 3750 60  0000 C CNN
F 3 "" H 5600 3750 60  0000 C CNN
	1    5600 3750
	1    0    0    -1  
$EndComp
$Comp
L R R9
U 1 1 55772335
P 5250 5000
F 0 "R9" V 5330 5000 40  0000 C CNN
F 1 "4k7" V 5257 5001 40  0000 C CNN
F 2 "~" V 5180 5000 30  0000 C CNN
F 3 "~" H 5250 5000 30  0000 C CNN
	1    5250 5000
	0    -1   -1   0   
$EndComp
$Comp
L R R2
U 1 1 557723B5
P 3400 5900
F 0 "R2" V 3480 5900 40  0000 C CNN
F 1 "120R" V 3407 5901 40  0000 C CNN
F 2 "~" V 3330 5900 30  0000 C CNN
F 3 "~" H 3400 5900 30  0000 C CNN
	1    3400 5900
	0    -1   -1   0   
$EndComp
$Comp
L R R4
U 1 1 557723D1
P 3800 5550
F 0 "R4" V 3880 5550 40  0000 C CNN
F 1 "680R" V 3807 5551 40  0000 C CNN
F 2 "~" V 3730 5550 30  0000 C CNN
F 3 "~" H 3800 5550 30  0000 C CNN
	1    3800 5550
	-1   0    0    1   
$EndComp
$Comp
L GND #PWR16
U 1 1 55772493
P 6000 5650
F 0 "#PWR16" H 6000 5650 30  0001 C CNN
F 1 "GND" H 6000 5580 30  0001 C CNN
F 2 "" H 6000 5650 60  0000 C CNN
F 3 "" H 6000 5650 60  0000 C CNN
	1    6000 5650
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR14
U 1 1 5577274E
P 5000 6500
F 0 "#PWR14" H 5000 6500 30  0001 C CNN
F 1 "GND" H 5000 6430 30  0001 C CNN
F 2 "" H 5000 6500 60  0000 C CNN
F 3 "" H 5000 6500 60  0000 C CNN
	1    5000 6500
	1    0    0    -1  
$EndComp
Text GLabel 3800 5200 1    39   Input ~ 0
SYNC
Text Notes 7550 5000 2    60   ~ 0
audio out
Text Notes 5650 5900 2    60   ~ 0
video out
Text GLabel 4550 4000 0    39   Input ~ 0
SYNC
$Comp
L CONN_5 P1
U 1 1 557729BF
P 4550 1800
F 0 "P1" V 4500 1800 50  0000 C CNN
F 1 "ICSP" V 4600 1800 50  0000 C CNN
F 2 "" H 4550 1800 60  0000 C CNN
F 3 "" H 4550 1800 60  0000 C CNN
	1    4550 1800
	0    1    -1   0   
$EndComp
$Comp
L R R5
U 1 1 557729D3
P 4150 3000
F 0 "R5" V 4230 3000 40  0000 C CNN
F 1 "470R" V 4157 3001 40  0000 C CNN
F 2 "~" V 4080 3000 30  0000 C CNN
F 3 "~" H 4150 3000 30  0000 C CNN
	1    4150 3000
	0    -1   -1   0   
$EndComp
$Comp
L R R3
U 1 1 557729E0
P 3600 2750
F 0 "R3" V 3680 2750 40  0000 C CNN
F 1 "10K" V 3607 2751 40  0000 C CNN
F 2 "~" V 3530 2750 30  0000 C CNN
F 3 "~" H 3600 2750 30  0000 C CNN
	1    3600 2750
	-1   0    0    1   
$EndComp
$Comp
L C C5
U 1 1 557729E8
P 3600 3300
F 0 "C5" H 3600 3400 40  0000 L CNN
F 1 "100nF" H 3606 3215 40  0000 L CNN
F 2 "~" H 3638 3150 30  0000 C CNN
F 3 "~" H 3600 3300 60  0000 C CNN
	1    3600 3300
	1    0    0    -1  
$EndComp
$Comp
L SW_PUSH_SMALL SW2
U 1 1 557729F7
P 3200 3150
F 0 "SW2" H 3250 3250 30  0000 C CNN
F 1 "reset" H 3350 3150 30  0000 C CNN
F 2 "~" H 3200 3150 60  0000 C CNN
F 3 "~" H 3200 3150 60  0000 C CNN
	1    3200 3150
	-1   0    0    -1  
$EndComp
$Comp
L GND #PWR9
U 1 1 55772AE7
P 3600 3600
F 0 "#PWR9" H 3600 3600 30  0001 C CNN
F 1 "GND" H 3600 3530 30  0001 C CNN
F 2 "" H 3600 3600 60  0000 C CNN
F 3 "" H 3600 3600 60  0000 C CNN
	1    3600 3600
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR6
U 1 1 55772AF4
P 3100 3600
F 0 "#PWR6" H 3100 3600 30  0001 C CNN
F 1 "GND" H 3100 3530 30  0001 C CNN
F 2 "" H 3100 3600 60  0000 C CNN
F 3 "" H 3100 3600 60  0000 C CNN
	1    3100 3600
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR11
U 1 1 55772BB1
P 4550 2500
F 0 "#PWR11" H 4550 2500 30  0001 C CNN
F 1 "GND" H 4550 2430 30  0001 C CNN
F 2 "" H 4550 2500 60  0000 C CNN
F 3 "" H 4550 2500 60  0000 C CNN
	1    4550 2500
	1    0    0    -1  
$EndComp
Text GLabel 3600 2200 1    60   Input ~ 0
+3V
Text GLabel 4050 4200 0    39   Input ~ 0
+3V
$Comp
L C C6
U 1 1 55772EC6
P 4200 4400
F 0 "C6" H 4200 4500 40  0000 L CNN
F 1 "100nF" H 4206 4315 40  0000 L CNN
F 2 "~" H 4238 4250 30  0000 C CNN
F 3 "~" H 4200 4400 60  0000 C CNN
	1    4200 4400
	1    0    0    -1  
$EndComp
$Comp
L C C9
U 1 1 55772ECC
P 6750 2650
F 0 "C9" H 6750 2750 40  0000 L CNN
F 1 "100nF" H 6756 2565 40  0000 L CNN
F 2 "~" H 6788 2500 30  0000 C CNN
F 3 "~" H 6750 2650 60  0000 C CNN
	1    6750 2650
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR18
U 1 1 55772ED2
P 6950 2850
F 0 "#PWR18" H 6950 2850 30  0001 C CNN
F 1 "GND" H 6950 2780 30  0001 C CNN
F 2 "" H 6950 2850 60  0000 C CNN
F 3 "" H 6950 2850 60  0000 C CNN
	1    6950 2850
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR10
U 1 1 55772F91
P 4200 4700
F 0 "#PWR10" H 4200 4700 30  0001 C CNN
F 1 "GND" H 4200 4630 30  0001 C CNN
F 2 "" H 4200 4700 60  0000 C CNN
F 3 "" H 4200 4700 60  0000 C CNN
	1    4200 4700
	1    0    0    -1  
$EndComp
$Comp
L CAPAPOL C10
U 1 1 55773066
P 6850 3800
F 0 "C10" H 6900 3900 40  0000 L CNN
F 1 "47µF" H 6900 3700 40  0000 L CNN
F 2 "~" H 6950 3650 30  0000 C CNN
F 3 "~" H 6850 3800 300 0000 C CNN
	1    6850 3800
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR19
U 1 1 55773073
P 7200 4150
F 0 "#PWR19" H 7200 4150 30  0001 C CNN
F 1 "GND" H 7200 4080 30  0001 C CNN
F 2 "" H 7200 4150 60  0000 C CNN
F 3 "" H 7200 4150 60  0000 C CNN
	1    7200 4150
	1    0    0    -1  
$EndComp
Text GLabel 9400 1650 2    39   Input ~ 0
KBCLK
Text GLabel 9350 2250 2    39   Input ~ 0
KBDAT
Text GLabel 7450 3300 2    39   Input ~ 0
KBCLK
Text GLabel 7450 3200 2    39   Input ~ 0
KBDAT
$Comp
L CRYSTAL X1
U 1 1 557735F2
P 3100 3900
F 0 "X1" H 3100 4050 60  0000 C CNN
F 1 "8Mhz" H 3100 3750 60  0000 C CNN
F 2 "~" H 3100 3900 60  0000 C CNN
F 3 "~" H 3100 3900 60  0000 C CNN
	1    3100 3900
	1    0    0    -1  
$EndComp
$Comp
L C C4
U 1 1 557736BE
P 3400 4250
F 0 "C4" H 3400 4350 40  0000 L CNN
F 1 "18pF" H 3406 4165 40  0000 L CNN
F 2 "~" H 3438 4100 30  0000 C CNN
F 3 "~" H 3400 4250 60  0000 C CNN
	1    3400 4250
	1    0    0    -1  
$EndComp
$Comp
L C C3
U 1 1 557736CB
P 2800 4250
F 0 "C3" H 2800 4350 40  0000 L CNN
F 1 "18pF" H 2806 4165 40  0000 L CNN
F 2 "~" H 2838 4100 30  0000 C CNN
F 3 "~" H 2800 4250 60  0000 C CNN
	1    2800 4250
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR8
U 1 1 55773799
P 3400 4600
F 0 "#PWR8" H 3400 4600 30  0001 C CNN
F 1 "GND" H 3400 4530 30  0001 C CNN
F 2 "" H 3400 4600 60  0000 C CNN
F 3 "" H 3400 4600 60  0000 C CNN
	1    3400 4600
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR5
U 1 1 5577379F
P 2800 4600
F 0 "#PWR5" H 2800 4600 30  0001 C CNN
F 1 "GND" H 2800 4530 30  0001 C CNN
F 2 "" H 2800 4600 60  0000 C CNN
F 3 "" H 2800 4600 60  0000 C CNN
	1    2800 4600
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR21
U 1 1 55773979
P 9050 4000
F 0 "#PWR21" H 9050 4000 30  0001 C CNN
F 1 "GND" H 9050 3930 30  0001 C CNN
F 2 "" H 9050 4000 60  0000 C CNN
F 3 "" H 9050 4000 60  0000 C CNN
	1    9050 4000
	1    0    0    -1  
$EndComp
$Comp
L C C11
U 1 1 55773ACD
P 10400 3500
F 0 "C11" H 10400 3600 40  0000 L CNN
F 1 "100nF" H 10406 3415 40  0000 L CNN
F 2 "~" H 10438 3350 30  0000 C CNN
F 3 "~" H 10400 3500 60  0000 C CNN
	1    10400 3500
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR24
U 1 1 55773B44
P 10600 3650
F 0 "#PWR24" H 10600 3650 30  0001 C CNN
F 1 "GND" H 10600 3580 30  0001 C CNN
F 2 "" H 10600 3650 60  0000 C CNN
F 3 "" H 10600 3650 60  0000 C CNN
	1    10600 3650
	1    0    0    -1  
$EndComp
$Comp
L R R11
U 1 1 55773BD0
P 8700 3200
F 0 "R11" V 8780 3200 40  0000 C CNN
F 1 "10k" V 8707 3201 40  0000 C CNN
F 2 "~" V 8630 3200 30  0000 C CNN
F 3 "~" H 8700 3200 30  0000 C CNN
	1    8700 3200
	1    0    0    -1  
$EndComp
Text GLabel 6400 4000 2    39   Input ~ 0
~SS1
Text GLabel 6400 4100 2    39   Input ~ 0
SCLK
Text GLabel 6400 4200 2    39   Input ~ 0
MISO
Text GLabel 6400 4300 2    39   Input ~ 0
MOSI
Text GLabel 8550 3500 0    39   Input ~ 0
~SS1
Text GLabel 8550 3600 0    39   Input ~ 0
MISO
Text GLabel 10250 3800 2    39   Input ~ 0
MOSI
Text GLabel 10250 3700 2    39   Input ~ 0
SCLK
$Comp
L 23LC512 U3
U 1 1 5577474D
P 9550 3700
F 0 "U3" H 9550 3500 60  0000 C CNN
F 1 "25LC1024" H 9550 4000 60  0000 C CNN
F 2 "" H 9550 3700 60  0000 C CNN
F 3 "" H 9550 3700 60  0000 C CNN
	1    9550 3700
	1    0    0    -1  
$EndComp
$Comp
L BATTERY BT1
U 1 1 55775616
P 2850 1200
F 0 "BT1" H 2850 1400 50  0000 C CNN
F 1 "2 x AA" H 2850 1010 50  0000 C CNN
F 2 "~" H 2850 1200 60  0000 C CNN
F 3 "~" H 2850 1200 60  0000 C CNN
	1    2850 1200
	1    0    0    -1  
$EndComp
$Comp
L SWITCH_INV SW1
U 1 1 55775625
P 2250 2250
F 0 "SW1" H 2050 2400 50  0000 C CNN
F 1 "Power" H 2100 2100 50  0000 C CNN
F 2 "~" H 2250 2250 60  0000 C CNN
F 3 "~" H 2250 2250 60  0000 C CNN
	1    2250 2250
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR1
U 1 1 55775634
P 1400 3100
F 0 "#PWR1" H 1400 3100 30  0001 C CNN
F 1 "GND" H 1400 3030 30  0001 C CNN
F 2 "" H 1400 3100 60  0000 C CNN
F 3 "" H 1400 3100 60  0000 C CNN
	1    1400 3100
	1    0    0    -1  
$EndComp
$Comp
L R R13
U 1 1 55778C04
P 8950 3200
F 0 "R13" V 9030 3200 40  0000 C CNN
F 1 "10k" V 8957 3201 40  0000 C CNN
F 2 "~" V 8880 3200 30  0000 C CNN
F 3 "~" H 8950 3200 30  0000 C CNN
	1    8950 3200
	1    0    0    -1  
$EndComp
Text GLabel 8950 2700 1    39   Input ~ 0
+3V
$Comp
L GND #PWR12
U 1 1 557795A1
P 4600 3700
F 0 "#PWR12" H 4600 3700 30  0001 C CNN
F 1 "GND" H 4600 3630 30  0001 C CNN
F 2 "" H 4600 3700 60  0000 C CNN
F 3 "" H 4600 3700 60  0000 C CNN
	1    4600 3700
	0    1    1    0   
$EndComp
$Comp
L PS/2 J4
U 1 1 557C962A
P 8750 2000
F 0 "J4" H 8750 1650 60  0000 C CNN
F 1 "PS/2" H 8750 2450 60  0000 C CNN
F 2 "~" H 8750 2000 60  0000 C CNN
F 3 "~" H 8750 2000 60  0000 C CNN
	1    8750 2000
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR23
U 1 1 557C96D6
P 9600 2100
F 0 "#PWR23" H 9600 2100 30  0001 C CNN
F 1 "GND" H 9600 2030 30  0001 C CNN
F 2 "" H 9600 2100 60  0000 C CNN
F 3 "" H 9600 2100 60  0000 C CNN
	1    9600 2100
	1    0    0    -1  
$EndComp
$Comp
L R R6
U 1 1 557C98D1
P 7100 2800
F 0 "R6" V 7180 2800 40  0000 C CNN
F 1 "10K" V 7107 2801 40  0000 C CNN
F 2 "~" V 7030 2800 30  0000 C CNN
F 3 "~" H 7100 2800 30  0000 C CNN
	1    7100 2800
	-1   0    0    1   
$EndComp
$Comp
L R R8
U 1 1 557C98D7
P 7300 2800
F 0 "R8" V 7380 2800 40  0000 C CNN
F 1 "10K" V 7307 2801 40  0000 C CNN
F 2 "~" V 7230 2800 30  0000 C CNN
F 3 "~" H 7300 2800 30  0000 C CNN
	1    7300 2800
	-1   0    0    1   
$EndComp
$Comp
L R R1
U 1 1 557C9D70
P 2800 2650
F 0 "R1" V 2880 2650 40  0000 C CNN
F 1 "150R" V 2807 2651 40  0000 C CNN
F 2 "~" V 2730 2650 30  0000 C CNN
F 3 "~" H 2800 2650 30  0000 C CNN
	1    2800 2650
	1    0    0    -1  
$EndComp
$Comp
L LED D1
U 1 1 557C9D7F
P 2800 3200
F 0 "D1" H 2800 3300 50  0000 C CNN
F 1 "LED" H 2800 3100 50  0000 C CNN
F 2 "~" H 2800 3200 60  0000 C CNN
F 3 "~" H 2800 3200 60  0000 C CNN
	1    2800 3200
	0    1    1    0   
$EndComp
$Comp
L GND #PWR4
U 1 1 557C9D8C
P 2800 3500
F 0 "#PWR4" H 2800 3500 30  0001 C CNN
F 1 "GND" H 2800 3430 30  0001 C CNN
F 2 "" H 2800 3500 60  0000 C CNN
F 3 "" H 2800 3500 60  0000 C CNN
	1    2800 3500
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR2
U 1 1 557CC219
P 1900 1650
F 0 "#PWR2" H 1900 1650 30  0001 C CNN
F 1 "GND" H 1900 1580 30  0001 C CNN
F 2 "" H 1900 1650 60  0000 C CNN
F 3 "" H 1900 1650 60  0000 C CNN
	1    1900 1650
	1    0    0    -1  
$EndComp
$Comp
L BARREL_JACK CON1
U 1 1 557CC230
P 3600 1200
F 0 "CON1" H 3600 1450 60  0000 C CNN
F 1 "BARREL_JACK 2,1mm" H 3400 1000 60  0000 C CNN
F 2 "~" H 3600 1200 60  0000 C CNN
F 3 "~" H 3600 1200 60  0000 C CNN
	1    3600 1200
	-1   0    0    -1  
$EndComp
$Comp
L GND #PWR7
U 1 1 557CC2EB
P 3300 1550
F 0 "#PWR7" H 3300 1550 30  0001 C CNN
F 1 "GND" H 3300 1480 30  0001 C CNN
F 2 "" H 3300 1550 60  0000 C CNN
F 3 "" H 3300 1550 60  0000 C CNN
	1    3300 1550
	1    0    0    -1  
$EndComp
$Comp
L CAPAPOL C1
U 1 1 557CC7F0
P 1400 2550
F 0 "C1" H 1450 2650 40  0000 L CNN
F 1 "47µF" H 1450 2450 40  0000 L CNN
F 2 "~" H 1500 2400 30  0000 C CNN
F 3 "~" H 1400 2550 300 0000 C CNN
	1    1400 2550
	1    0    0    -1  
$EndComp
$Comp
L C C2
U 1 1 557CC8BB
P 2400 1050
F 0 "C2" H 2400 1150 40  0000 L CNN
F 1 "100nF" H 2406 965 40  0000 L CNN
F 2 "~" H 2438 900 30  0000 C CNN
F 3 "~" H 2400 1050 60  0000 C CNN
	1    2400 1050
	1    0    0    -1  
$EndComp
Text Notes 4050 1100 0    39   ~ 0
power adapter jack\n5-9 volts DC
$Comp
L LD33V U1
U 1 1 557CCDC4
P 2000 1150
F 0 "U1" H 2000 1450 60  0000 C CNN
F 1 "LD1117v33" H 2000 1350 60  0000 C CNN
F 2 "" H 2000 1150 60  0000 C CNN
F 3 "" H 2000 1150 60  0000 C CNN
	1    2000 1150
	1    0    0    -1  
$EndComp
Text Notes 2450 2450 0    39   ~ 0
ON
Text Notes 2450 2150 0    39   ~ 0
OFF
$Comp
L RCA_JACK J2
U 1 1 557CCF5B
P 6900 5000
F 0 "J2" H 6900 5100 60  0000 C CNN
F 1 "RCA_JACK" H 6900 5300 60  0000 C CNN
F 2 "~" H 6900 5000 60  0000 C CNN
F 3 "~" H 6900 5000 60  0000 C CNN
	1    6900 5000
	-1   0    0    -1  
$EndComp
$Comp
L RCA_JACK J1
U 1 1 557CCF74
P 5000 5900
F 0 "J1" H 5000 6000 60  0000 C CNN
F 1 "RCA_JACK" H 4950 6150 60  0000 C CNN
F 2 "~" H 5000 5900 60  0000 C CNN
F 3 "~" H 5000 5900 60  0000 C CNN
	1    5000 5900
	-1   0    0    -1  
$EndComp
$Comp
L GND #PWR17
U 1 1 557CD0FD
P 6900 5600
F 0 "#PWR17" H 6900 5600 30  0001 C CNN
F 1 "GND" H 6900 5530 30  0001 C CNN
F 2 "" H 6900 5600 60  0000 C CNN
F 3 "" H 6900 5600 60  0000 C CNN
	1    6900 5600
	1    0    0    -1  
$EndComp
$Comp
L R R10
U 1 1 557F975C
P 6000 5250
F 0 "R10" V 6080 5250 40  0000 C CNN
F 1 "1K" V 6007 5251 40  0000 C CNN
F 2 "~" V 5930 5250 30  0000 C CNN
F 3 "~" H 6000 5250 30  0000 C CNN
	1    6000 5250
	1    0    0    -1  
$EndComp
Text GLabel 4500 3600 0    39   Input ~ 0
Vidout
Text GLabel 3000 5900 0    39   Input ~ 0
Vidout
$Comp
L GND #PWR22
U 1 1 55FA1459
P 9050 5750
F 0 "#PWR22" H 9050 5750 30  0001 C CNN
F 1 "GND" H 9050 5680 30  0001 C CNN
F 2 "" H 9050 5750 60  0000 C CNN
F 3 "" H 9050 5750 60  0000 C CNN
	1    9050 5750
	1    0    0    -1  
$EndComp
$Comp
L C C12
U 1 1 55FA145F
P 10400 5250
F 0 "C12" H 10400 5350 40  0000 L CNN
F 1 "100nF" H 10406 5165 40  0000 L CNN
F 2 "~" H 10438 5100 30  0000 C CNN
F 3 "~" H 10400 5250 60  0000 C CNN
	1    10400 5250
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR25
U 1 1 55FA1465
P 10600 5400
F 0 "#PWR25" H 10600 5400 30  0001 C CNN
F 1 "GND" H 10600 5330 30  0001 C CNN
F 2 "" H 10600 5400 60  0000 C CNN
F 3 "" H 10600 5400 60  0000 C CNN
	1    10600 5400
	1    0    0    -1  
$EndComp
Text GLabel 8550 5250 0    39   Input ~ 0
~SS2
Text GLabel 8550 5350 0    39   Input ~ 0
MISO
Text GLabel 10250 5550 2    39   Input ~ 0
MOSI
Text GLabel 10250 5450 2    39   Input ~ 0
SCLK
$Comp
L 23LC512 U4
U 1 1 55FA1475
P 9550 5450
F 0 "U4" H 9550 5250 60  0000 C CNN
F 1 "23LC1024" H 9550 5750 60  0000 C CNN
F 2 "" H 9550 5450 60  0000 C CNN
F 3 "" H 9550 5450 60  0000 C CNN
	1    9550 5450
	1    0    0    -1  
$EndComp
$Comp
L R R12
U 1 1 55FA147B
P 8700 4950
F 0 "R12" V 8780 4950 40  0000 C CNN
F 1 "10k" V 8707 4951 40  0000 C CNN
F 2 "~" V 8630 4950 30  0000 C CNN
F 3 "~" H 8700 4950 30  0000 C CNN
	1    8700 4950
	1    0    0    -1  
$EndComp
Text GLabel 8950 4450 1    39   Input ~ 0
+3V
Text GLabel 6400 3700 2    39   Input ~ 0
~SS2
$Comp
L USB-A_F J3
U 1 1 55FAA10F
P 8650 1100
F 0 "J3" H 8620 800 60  0000 C CNN
F 1 "USB-A_F" H 8650 1400 60  0000 C CNN
F 2 "" H 8610 1110 60  0000 C CNN
F 3 "" H 8610 1110 60  0000 C CNN
	1    8650 1100
	1    0    0    -1  
$EndComp
Text GLabel 8100 1100 0    39   Input ~ 0
KBCLK
Text GLabel 8100 1000 0    39   Input ~ 0
KBDAT
Text GLabel 8100 900  0    39   Input ~ 0
+3V
$Comp
L GND #PWR20
U 1 1 55FAF833
P 8200 1300
F 0 "#PWR20" H 8200 1300 30  0001 C CNN
F 1 "GND" H 8200 1230 30  0001 C CNN
F 2 "" H 8200 1300 60  0000 C CNN
F 3 "" H 8200 1300 60  0000 C CNN
	1    8200 1300
	1    0    0    -1  
$EndComp
Text Notes 7800 800  0    60   ~ 0
option 1
Text Notes 7800 1600 0    60   ~ 0
option 2
Text GLabel 7950 1950 0    39   Input ~ 0
+3V
Text Notes 9150 1200 0    60   ~ 0
connecteur clavier\n
$Comp
L GND #PWR3
U 1 1 5600DB37
P 2400 1300
F 0 "#PWR3" H 2400 1300 30  0001 C CNN
F 1 "GND" H 2400 1230 30  0001 C CNN
F 2 "" H 2400 1300 60  0000 C CNN
F 3 "" H 2400 1300 60  0000 C CNN
	1    2400 1300
	1    0    0    -1  
$EndComp
$Comp
L R R7
U 1 1 5601461A
P 4750 4550
F 0 "R7" V 4830 4550 40  0000 C CNN
F 1 "4k7" V 4757 4551 40  0000 C CNN
F 2 "~" V 4680 4550 30  0000 C CNN
F 3 "~" H 4750 4550 30  0000 C CNN
	1    4750 4550
	1    0    0    -1  
$EndComp
$Comp
L C C7
U 1 1 5601470A
P 4750 5200
F 0 "C7" H 4750 5300 40  0000 L CNN
F 1 "10nF" H 4756 5115 40  0000 L CNN
F 2 "~" H 4788 5050 30  0000 C CNN
F 3 "~" H 4750 5200 60  0000 C CNN
	1    4750 5200
	1    0    0    -1  
$EndComp
$Comp
L C C8
U 1 1 56014795
P 5650 5200
F 0 "C8" H 5650 5300 40  0000 L CNN
F 1 "22nF" H 5656 5115 40  0000 L CNN
F 2 "~" H 5688 5050 30  0000 C CNN
F 3 "~" H 5650 5200 60  0000 C CNN
	1    5650 5200
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR15
U 1 1 56014C24
P 5650 5450
F 0 "#PWR15" H 5650 5450 30  0001 C CNN
F 1 "GND" H 5650 5380 30  0001 C CNN
F 2 "" H 5650 5450 60  0000 C CNN
F 3 "" H 5650 5450 60  0000 C CNN
	1    5650 5450
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR13
U 1 1 56014C57
P 4750 5450
F 0 "#PWR13" H 4750 5450 30  0001 C CNN
F 1 "GND" H 4750 5380 30  0001 C CNN
F 2 "" H 4750 5450 60  0000 C CNN
F 3 "" H 4750 5450 60  0000 C CNN
	1    4750 5450
	1    0    0    -1  
$EndComp
Wire Wire Line
	6000 5500 6000 5650
Connection ~ 3800 5900
Wire Wire Line
	5500 5000 6550 5000
Wire Wire Line
	3800 5200 3800 5300
Wire Wire Line
	3800 5800 3800 5900
Wire Wire Line
	4550 4000 4900 4000
Wire Wire Line
	4750 2200 4750 3000
Wire Wire Line
	4400 3000 4900 3000
Wire Wire Line
	3900 3000 3600 3000
Wire Wire Line
	3600 3000 3600 3100
Wire Wire Line
	3300 3050 3600 3050
Connection ~ 3600 3050
Wire Wire Line
	3100 3250 3100 3600
Wire Wire Line
	3600 3500 3600 3600
Wire Wire Line
	4700 3300 4700 2750
Wire Wire Line
	4700 2750 4450 2750
Wire Wire Line
	4450 2750 4450 2200
Wire Wire Line
	4650 3400 4650 2800
Wire Wire Line
	4650 2800 4350 2800
Wire Wire Line
	4350 2800 4350 2200
Wire Wire Line
	4550 2200 4550 2500
Wire Wire Line
	3600 2200 3600 2500
Wire Wire Line
	4650 2200 4650 2350
Connection ~ 3600 2350
Wire Wire Line
	6400 2350 6400 3000
Connection ~ 4650 2350
Wire Wire Line
	6950 2650 6950 2850
Wire Wire Line
	6550 2650 6400 2650
Connection ~ 6400 2650
Wire Wire Line
	6250 3100 6850 3100
Wire Wire Line
	6850 3100 6850 2800
Connection ~ 6950 2800
Wire Wire Line
	4200 4600 4200 4700
Wire Wire Line
	4050 4200 4900 4200
Wire Wire Line
	7200 3800 7200 4150
Wire Wire Line
	7200 3800 7050 3800
Wire Wire Line
	6650 3800 6250 3800
Connection ~ 7200 4000
Connection ~ 6400 2350
Wire Wire Line
	2800 4450 2800 4600
Wire Wire Line
	3400 4450 3400 4600
Wire Wire Line
	10100 2850 10100 3600
Wire Wire Line
	10100 3500 10200 3500
Wire Wire Line
	10600 3500 10600 3650
Wire Wire Line
	3650 5900 4650 5900
Wire Wire Line
	6400 4000 6250 4000
Wire Wire Line
	8550 3500 9050 3500
Wire Wire Line
	8550 3600 9050 3600
Wire Wire Line
	10250 3800 10100 3800
Wire Wire Line
	10250 3700 10100 3700
Connection ~ 10100 3500
Wire Wire Line
	1400 2750 1400 3100
Wire Wire Line
	1400 2350 1400 2250
Wire Wire Line
	1400 2250 1750 2250
Wire Wire Line
	6750 4000 7200 4000
Wire Wire Line
	6750 4000 6750 3900
Wire Wire Line
	6750 3900 6250 3900
Wire Wire Line
	6250 4300 6400 4300
Wire Wire Line
	6250 4100 6400 4100
Wire Wire Line
	6400 4200 6250 4200
Wire Wire Line
	8950 3450 8950 3500
Connection ~ 8950 3500
Wire Wire Line
	4600 3700 4900 3700
Wire Wire Line
	3400 4050 3400 3900
Wire Wire Line
	3400 3900 4900 3900
Wire Wire Line
	2800 4050 2800 3700
Wire Wire Line
	2800 3700 4100 3700
Wire Wire Line
	4100 3700 4100 3800
Wire Wire Line
	4100 3800 4900 3800
Wire Wire Line
	9450 1950 9600 1950
Wire Wire Line
	9600 1950 9600 2100
Wire Wire Line
	9400 1650 9300 1650
Wire Wire Line
	9350 2250 9250 2250
Wire Wire Line
	2800 2400 2800 2350
Wire Wire Line
	2800 2900 2800 3000
Wire Wire Line
	2800 3400 2800 3500
Wire Wire Line
	2300 800  2300 1550
Wire Wire Line
	2300 1550 2100 1550
Wire Wire Line
	3300 1300 3300 1550
Wire Wire Line
	2000 1550 2000 1950
Wire Wire Line
	1750 1950 2550 1950
Wire Wire Line
	1750 2250 1750 1950
Wire Wire Line
	3150 1200 3300 1200
Wire Wire Line
	3300 1100 3300 800 
Wire Wire Line
	3300 800  2300 800 
Wire Wire Line
	2550 1950 2550 1200
Connection ~ 2000 1950
Wire Wire Line
	5000 6400 5000 6500
Wire Wire Line
	6900 5500 6900 5600
Wire Wire Line
	6850 2800 6950 2800
Wire Wire Line
	4700 3300 4900 3300
Wire Wire Line
	4650 3400 4900 3400
Wire Wire Line
	8950 2700 8950 2950
Wire Wire Line
	8700 2850 10100 2850
Connection ~ 8950 2850
Wire Wire Line
	8700 2850 8700 2950
Wire Wire Line
	8700 3450 8700 3600
Connection ~ 8700 3600
Wire Wire Line
	4500 3600 4900 3600
Wire Wire Line
	3000 5900 3150 5900
Wire Wire Line
	6400 3000 6250 3000
Connection ~ 4750 3000
Wire Wire Line
	9050 3800 9050 4000
Wire Wire Line
	9050 3700 8850 3700
Wire Wire Line
	8850 3700 8850 2850
Connection ~ 8850 2850
Wire Wire Line
	10100 4600 10100 5350
Wire Wire Line
	10100 5250 10200 5250
Wire Wire Line
	10600 5250 10600 5400
Wire Wire Line
	8550 5250 9050 5250
Wire Wire Line
	8550 5350 9050 5350
Wire Wire Line
	10250 5550 10100 5550
Wire Wire Line
	10250 5450 10100 5450
Connection ~ 10100 5250
Wire Wire Line
	8700 4600 10100 4600
Connection ~ 8950 4600
Wire Wire Line
	9050 5550 9050 5750
Wire Wire Line
	9050 5450 8850 5450
Wire Wire Line
	8850 5450 8850 4600
Connection ~ 8850 4600
Wire Wire Line
	6250 3700 6400 3700
Wire Wire Line
	8200 1100 8100 1100
Wire Wire Line
	8100 1000 8200 1000
Wire Wire Line
	8100 900  8200 900 
Wire Wire Line
	8200 1200 8200 1300
Wire Bus Line
	7750 700  7750 1450
Wire Bus Line
	7750 1450 9100 1450
Wire Bus Line
	9100 1450 9100 700 
Wire Bus Line
	9100 700  7750 700 
Wire Bus Line
	7900 2450 9850 2450
Wire Bus Line
	9850 2450 9850 1500
Wire Bus Line
	9850 1500 7750 1500
Connection ~ 2800 2350
Wire Wire Line
	2750 2350 7300 2350
Wire Wire Line
	7950 1950 8050 1950
Wire Bus Line
	7750 1500 7750 2450
Wire Bus Line
	7750 2450 7950 2450
Wire Wire Line
	2400 850  2400 800 
Connection ~ 2400 800 
Wire Wire Line
	2400 1250 2400 1300
Wire Wire Line
	1900 1550 1900 1650
Wire Wire Line
	8700 4600 8700 4700
Wire Wire Line
	8700 5200 8700 5250
Connection ~ 8700 5250
Wire Wire Line
	8950 4450 8950 4600
Wire Wire Line
	4900 4300 4750 4300
Connection ~ 6000 5000
Wire Wire Line
	4750 4800 4750 5000
Wire Wire Line
	4750 5000 5000 5000
Wire Wire Line
	4750 5400 4750 5450
Wire Wire Line
	5650 5400 5650 5450
Wire Wire Line
	6250 3300 7450 3300
Wire Wire Line
	6250 3200 7450 3200
Wire Wire Line
	7100 3050 7100 3200
Connection ~ 7100 3200
Wire Wire Line
	7300 3050 7300 3300
Connection ~ 7300 3300
Wire Wire Line
	7100 2350 7100 2550
Wire Wire Line
	7300 2350 7300 2550
Connection ~ 7100 2350
$EndSCHEMATC
