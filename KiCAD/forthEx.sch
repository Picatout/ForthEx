EESchema Schematic File Version 2
LIBS:forthEx-rescue
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
LIBS:Personal_KiCAD
EELAYER 25 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 3
Title ""
Date "2 oct 2015"
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L R-RESCUE-forthEx R11
U 1 1 55772335
P 5550 5050
F 0 "R11" V 5630 5050 40  0000 C CNN
F 1 "4k7" V 5557 5051 40  0000 C CNN
F 2 "~" V 5480 5050 30  0000 C CNN
F 3 "~" H 5550 5050 30  0000 C CNN
	1    5550 5050
	0    -1   -1   0   
$EndComp
$Comp
L R-RESCUE-forthEx R8
U 1 1 557723B5
P 4950 6850
F 0 "R8" V 5030 6850 40  0000 C CNN
F 1 "120R" V 4957 6851 40  0000 C CNN
F 2 "~" V 4880 6850 30  0000 C CNN
F 3 "~" H 4950 6850 30  0000 C CNN
	1    4950 6850
	0    -1   -1   0   
$EndComp
$Comp
L R-RESCUE-forthEx R10
U 1 1 557723D1
P 5350 6500
F 0 "R10" V 5430 6500 40  0000 C CNN
F 1 "680R" V 5357 6501 40  0000 C CNN
F 2 "~" V 5280 6500 30  0000 C CNN
F 3 "~" H 5350 6500 30  0000 C CNN
	1    5350 6500
	-1   0    0    1   
$EndComp
$Comp
L GND #PWR24
U 1 1 55772493
P 6300 5700
F 0 "#PWR24" H 6300 5700 30  0001 C CNN
F 1 "GND" H 6300 5630 30  0001 C CNN
F 2 "" H 6300 5700 60  0000 C CNN
F 3 "" H 6300 5700 60  0000 C CNN
	1    6300 5700
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR22
U 1 1 5577274E
P 5950 7450
F 0 "#PWR22" H 5950 7450 30  0001 C CNN
F 1 "GND" H 5950 7380 30  0001 C CNN
F 2 "" H 5950 7450 60  0000 C CNN
F 3 "" H 5950 7450 60  0000 C CNN
	1    5950 7450
	1    0    0    -1  
$EndComp
Text GLabel 5350 6150 1    39   Input ~ 0
SYNC
Text Notes 7850 5050 2    60   ~ 0
audio out
Text Notes 6600 6850 2    60   ~ 0
video out
Text GLabel 4850 4050 0    39   Input ~ 0
SYNC
$Comp
L CONN_5 P1
U 1 1 557729BF
P 4850 1850
F 0 "P1" V 4800 1850 50  0000 C CNN
F 1 "ICSP" V 4900 1850 50  0000 C CNN
F 2 "" H 4850 1850 60  0000 C CNN
F 3 "" H 4850 1850 60  0000 C CNN
	1    4850 1850
	0    1    -1   0   
$EndComp
$Comp
L R-RESCUE-forthEx R7
U 1 1 557729D3
P 4450 3050
F 0 "R7" V 4530 3050 40  0000 C CNN
F 1 "470R" V 4457 3051 40  0000 C CNN
F 2 "~" V 4380 3050 30  0000 C CNN
F 3 "~" H 4450 3050 30  0000 C CNN
	1    4450 3050
	0    -1   -1   0   
$EndComp
$Comp
L R-RESCUE-forthEx R6
U 1 1 557729E0
P 3900 2800
F 0 "R6" V 3980 2800 40  0000 C CNN
F 1 "10K" V 3907 2801 40  0000 C CNN
F 2 "~" V 3830 2800 30  0000 C CNN
F 3 "~" H 3900 2800 30  0000 C CNN
	1    3900 2800
	-1   0    0    1   
$EndComp
$Comp
L C-RESCUE-forthEx C7
U 1 1 557729E8
P 3900 3350
F 0 "C7" H 3900 3450 40  0000 L CNN
F 1 "100nF" H 3906 3265 40  0000 L CNN
F 2 "~" H 3938 3200 30  0000 C CNN
F 3 "~" H 3900 3350 60  0000 C CNN
	1    3900 3350
	1    0    0    -1  
$EndComp
$Comp
L SW_PUSH_SMALL SW2
U 1 1 557729F7
P 3500 3200
F 0 "SW2" H 3550 3300 30  0000 C CNN
F 1 "reset" H 3650 3200 30  0000 C CNN
F 2 "~" H 3500 3200 60  0000 C CNN
F 3 "~" H 3500 3200 60  0000 C CNN
	1    3500 3200
	-1   0    0    -1  
$EndComp
$Comp
L GND #PWR15
U 1 1 55772AE7
P 3900 3650
F 0 "#PWR15" H 3900 3650 30  0001 C CNN
F 1 "GND" H 3900 3580 30  0001 C CNN
F 2 "" H 3900 3650 60  0000 C CNN
F 3 "" H 3900 3650 60  0000 C CNN
	1    3900 3650
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR12
U 1 1 55772AF4
P 3400 3650
F 0 "#PWR12" H 3400 3650 30  0001 C CNN
F 1 "GND" H 3400 3580 30  0001 C CNN
F 2 "" H 3400 3650 60  0000 C CNN
F 3 "" H 3400 3650 60  0000 C CNN
	1    3400 3650
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR18
U 1 1 55772BB1
P 4850 2550
F 0 "#PWR18" H 4850 2550 30  0001 C CNN
F 1 "GND" H 4850 2480 30  0001 C CNN
F 2 "" H 4850 2550 60  0000 C CNN
F 3 "" H 4850 2550 60  0000 C CNN
	1    4850 2550
	1    0    0    -1  
$EndComp
Text GLabel 3900 2250 1    60   Input ~ 0
+3,3V
Text GLabel 4350 4250 0    39   Input ~ 0
+3,3V
$Comp
L C-RESCUE-forthEx C8
U 1 1 55772EC6
P 4500 4450
F 0 "C8" H 4500 4550 40  0000 L CNN
F 1 "100nF" H 4506 4365 40  0000 L CNN
F 2 "~" H 4538 4300 30  0000 C CNN
F 3 "~" H 4500 4450 60  0000 C CNN
	1    4500 4450
	1    0    0    -1  
$EndComp
$Comp
L C-RESCUE-forthEx C11
U 1 1 55772ECC
P 7200 2700
F 0 "C11" H 7200 2800 40  0000 L CNN
F 1 "100nF" H 7206 2615 40  0000 L CNN
F 2 "~" H 7238 2550 30  0000 C CNN
F 3 "~" H 7200 2700 60  0000 C CNN
	1    7200 2700
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR26
U 1 1 55772ED2
P 7400 2900
F 0 "#PWR26" H 7400 2900 30  0001 C CNN
F 1 "GND" H 7400 2830 30  0001 C CNN
F 2 "" H 7400 2900 60  0000 C CNN
F 3 "" H 7400 2900 60  0000 C CNN
	1    7400 2900
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR17
U 1 1 55772F91
P 4500 4750
F 0 "#PWR17" H 4500 4750 30  0001 C CNN
F 1 "GND" H 4500 4680 30  0001 C CNN
F 2 "" H 4500 4750 60  0000 C CNN
F 3 "" H 4500 4750 60  0000 C CNN
	1    4500 4750
	1    0    0    -1  
$EndComp
$Comp
L CAPAPOL C12
U 1 1 55773066
P 7300 3850
F 0 "C12" H 7350 3950 40  0000 L CNN
F 1 "47µF" H 7350 3750 40  0000 L CNN
F 2 "~" H 7400 3700 30  0000 C CNN
F 3 "~" H 7300 3850 300 0000 C CNN
	1    7300 3850
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR27
U 1 1 55773073
P 7650 4200
F 0 "#PWR27" H 7650 4200 30  0001 C CNN
F 1 "GND" H 7650 4130 30  0001 C CNN
F 2 "" H 7650 4200 60  0000 C CNN
F 3 "" H 7650 4200 60  0000 C CNN
	1    7650 4200
	1    0    0    -1  
$EndComp
$Comp
L CRYSTAL X1
U 1 1 557735F2
P 3400 3950
F 0 "X1" H 3400 4100 60  0000 C CNN
F 1 "8Mhz" H 3400 3800 60  0000 C CNN
F 2 "~" H 3400 3950 60  0000 C CNN
F 3 "~" H 3400 3950 60  0000 C CNN
	1    3400 3950
	1    0    0    -1  
$EndComp
$Comp
L C-RESCUE-forthEx C6
U 1 1 557736BE
P 3700 4300
F 0 "C6" H 3700 4400 40  0000 L CNN
F 1 "18pF" H 3706 4215 40  0000 L CNN
F 2 "~" H 3738 4150 30  0000 C CNN
F 3 "~" H 3700 4300 60  0000 C CNN
	1    3700 4300
	1    0    0    -1  
$EndComp
$Comp
L C-RESCUE-forthEx C4
U 1 1 557736CB
P 3100 4300
F 0 "C4" H 3100 4400 40  0000 L CNN
F 1 "18pF" H 3106 4215 40  0000 L CNN
F 2 "~" H 3138 4150 30  0000 C CNN
F 3 "~" H 3100 4300 60  0000 C CNN
	1    3100 4300
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR14
U 1 1 55773799
P 3700 4650
F 0 "#PWR14" H 3700 4650 30  0001 C CNN
F 1 "GND" H 3700 4580 30  0001 C CNN
F 2 "" H 3700 4650 60  0000 C CNN
F 3 "" H 3700 4650 60  0000 C CNN
	1    3700 4650
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR10
U 1 1 5577379F
P 3100 4650
F 0 "#PWR10" H 3100 4650 30  0001 C CNN
F 1 "GND" H 3100 4580 30  0001 C CNN
F 2 "" H 3100 4650 60  0000 C CNN
F 3 "" H 3100 4650 60  0000 C CNN
	1    3100 4650
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR28
U 1 1 55773979
P 9350 4050
F 0 "#PWR28" H 9350 4050 30  0001 C CNN
F 1 "GND" H 9350 3980 30  0001 C CNN
F 2 "" H 9350 4050 60  0000 C CNN
F 3 "" H 9350 4050 60  0000 C CNN
	1    9350 4050
	1    0    0    -1  
$EndComp
$Comp
L C-RESCUE-forthEx C13
U 1 1 55773ACD
P 10700 3550
F 0 "C13" H 10700 3650 40  0000 L CNN
F 1 "100nF" H 10706 3465 40  0000 L CNN
F 2 "~" H 10738 3400 30  0000 C CNN
F 3 "~" H 10700 3550 60  0000 C CNN
	1    10700 3550
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR30
U 1 1 55773B44
P 10900 3700
F 0 "#PWR30" H 10900 3700 30  0001 C CNN
F 1 "GND" H 10900 3630 30  0001 C CNN
F 2 "" H 10900 3700 60  0000 C CNN
F 3 "" H 10900 3700 60  0000 C CNN
	1    10900 3700
	1    0    0    -1  
$EndComp
$Comp
L R-RESCUE-forthEx R15
U 1 1 55773BD0
P 9000 3250
F 0 "R15" V 9080 3250 40  0000 C CNN
F 1 "10k" V 9007 3251 40  0000 C CNN
F 2 "~" V 8930 3250 30  0000 C CNN
F 3 "~" H 9000 3250 30  0000 C CNN
	1    9000 3250
	1    0    0    -1  
$EndComp
Text GLabel 6850 4350 2    39   Input ~ 0
~SS1
Text GLabel 6850 4250 2    39   Input ~ 0
SCLK
Text GLabel 6850 4050 2    39   Input ~ 0
MISO
Text GLabel 6850 4150 2    39   Input ~ 0
MOSI
Text GLabel 8850 3550 0    39   Input ~ 0
~SS1
Text GLabel 8850 3650 0    39   Input ~ 0
MISO
Text GLabel 10550 3850 2    39   Input ~ 0
MOSI
Text GLabel 10550 3750 2    39   Input ~ 0
SCLK
$Comp
L 23LC512 U4
U 1 1 5577474D
P 9850 3750
F 0 "U4" H 9850 3550 60  0000 C CNN
F 1 "25LC1024" H 9850 4050 60  0000 C CNN
F 2 "" H 9850 3750 60  0000 C CNN
F 3 "" H 9850 3750 60  0000 C CNN
	1    9850 3750
	1    0    0    -1  
$EndComp
$Comp
L SWITCH_INV SW1
U 1 1 55775625
P 2300 2300
F 0 "SW1" H 2100 2450 50  0000 C CNN
F 1 "Power" H 2150 2150 50  0000 C CNN
F 2 "~" H 2300 2300 60  0000 C CNN
F 3 "~" H 2300 2300 60  0000 C CNN
	1    2300 2300
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR3
U 1 1 55775634
P 1700 3150
F 0 "#PWR3" H 1700 3150 30  0001 C CNN
F 1 "GND" H 1700 3080 30  0001 C CNN
F 2 "" H 1700 3150 60  0000 C CNN
F 3 "" H 1700 3150 60  0000 C CNN
	1    1700 3150
	1    0    0    -1  
$EndComp
$Comp
L R-RESCUE-forthEx R17
U 1 1 55778C04
P 9250 3250
F 0 "R17" V 9330 3250 40  0000 C CNN
F 1 "10k" V 9257 3251 40  0000 C CNN
F 2 "~" V 9180 3250 30  0000 C CNN
F 3 "~" H 9250 3250 30  0000 C CNN
	1    9250 3250
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR19
U 1 1 557795A1
P 4900 3750
F 0 "#PWR19" H 4900 3750 30  0001 C CNN
F 1 "GND" H 4900 3680 30  0001 C CNN
F 2 "" H 4900 3750 60  0000 C CNN
F 3 "" H 4900 3750 60  0000 C CNN
	1    4900 3750
	0    1    1    0   
$EndComp
$Comp
L R-RESCUE-forthEx R13
U 1 1 557C98D1
P 7550 2850
F 0 "R13" V 7630 2850 40  0000 C CNN
F 1 "10K" V 7557 2851 40  0000 C CNN
F 2 "~" V 7480 2850 30  0000 C CNN
F 3 "~" H 7550 2850 30  0000 C CNN
	1    7550 2850
	-1   0    0    1   
$EndComp
$Comp
L R-RESCUE-forthEx R5
U 1 1 557C9D70
P 3100 2700
F 0 "R5" V 3180 2700 40  0000 C CNN
F 1 "150R" V 3107 2701 40  0000 C CNN
F 2 "~" V 3030 2700 30  0000 C CNN
F 3 "~" H 3100 2700 30  0000 C CNN
	1    3100 2700
	1    0    0    -1  
$EndComp
$Comp
L LED-RESCUE-forthEx D2
U 1 1 557C9D7F
P 3100 3250
F 0 "D2" H 3100 3350 50  0000 C CNN
F 1 "LED" H 3100 3150 50  0000 C CNN
F 2 "~" H 3100 3250 60  0000 C CNN
F 3 "~" H 3100 3250 60  0000 C CNN
	1    3100 3250
	0    1    1    0   
$EndComp
$Comp
L GND #PWR9
U 1 1 557C9D8C
P 3100 3550
F 0 "#PWR9" H 3100 3550 30  0001 C CNN
F 1 "GND" H 3100 3480 30  0001 C CNN
F 2 "" H 3100 3550 60  0000 C CNN
F 3 "" H 3100 3550 60  0000 C CNN
	1    3100 3550
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR2
U 1 1 557CC219
P 1600 1500
F 0 "#PWR2" H 1600 1500 30  0001 C CNN
F 1 "GND" H 1600 1430 30  0001 C CNN
F 2 "" H 1600 1500 60  0000 C CNN
F 3 "" H 1600 1500 60  0000 C CNN
	1    1600 1500
	1    0    0    -1  
$EndComp
$Comp
L BARREL_JACK CON2
U 1 1 557CC230
P 4500 950
F 0 "CON2" H 4500 1200 60  0000 C CNN
F 1 "BARREL_JACK 2,1mm" H 4300 750 60  0000 C CNN
F 2 "~" H 4500 950 60  0000 C CNN
F 3 "~" H 4500 950 60  0000 C CNN
	1    4500 950 
	-1   0    0    -1  
$EndComp
$Comp
L GND #PWR16
U 1 1 557CC2EB
P 4200 1300
F 0 "#PWR16" H 4200 1300 30  0001 C CNN
F 1 "GND" H 4200 1230 30  0001 C CNN
F 2 "" H 4200 1300 60  0000 C CNN
F 3 "" H 4200 1300 60  0000 C CNN
	1    4200 1300
	1    0    0    -1  
$EndComp
$Comp
L CAPAPOL C1
U 1 1 557CC7F0
P 1700 2600
F 0 "C1" H 1750 2700 40  0000 L CNN
F 1 "47µF" H 1750 2500 40  0000 L CNN
F 2 "~" H 1800 2450 30  0000 C CNN
F 3 "~" H 1700 2600 300 0000 C CNN
	1    1700 2600
	1    0    0    -1  
$EndComp
$Comp
L C-RESCUE-forthEx C3
U 1 1 557CC8BB
P 2700 1100
F 0 "C3" H 2700 1200 40  0000 L CNN
F 1 "100nF" H 2706 1015 40  0000 L CNN
F 2 "~" H 2738 950 30  0000 C CNN
F 3 "~" H 2700 1100 60  0000 C CNN
	1    2700 1100
	1    0    0    -1  
$EndComp
Text Notes 4750 750  0    39   ~ 0
power adapter jack\n7-12 volts DC
$Comp
L LD33V U1
U 1 1 557CCDC4
P 1700 1250
F 0 "U1" H 1700 1550 60  0000 C CNN
F 1 "LD1117v33" H 1700 1850 60  0000 C CNN
F 2 "" H 1700 1250 60  0000 C CNN
F 3 "" H 1700 1250 60  0000 C CNN
	1    1700 1250
	1    0    0    -1  
$EndComp
Text Notes 2500 2500 0    39   ~ 0
ON
Text Notes 2500 2200 0    39   ~ 0
OFF
$Comp
L RCA_JACK J2
U 1 1 557CCF5B
P 7200 5050
F 0 "J2" H 7200 5150 60  0000 C CNN
F 1 "RCA_JACK" H 7200 5350 60  0000 C CNN
F 2 "~" H 7200 5050 60  0000 C CNN
F 3 "~" H 7200 5050 60  0000 C CNN
	1    7200 5050
	-1   0    0    -1  
$EndComp
$Comp
L RCA_JACK J1
U 1 1 557CCF74
P 5950 6850
F 0 "J1" H 5950 6950 60  0000 C CNN
F 1 "RCA_JACK" H 5900 7100 60  0000 C CNN
F 2 "~" H 5950 6850 60  0000 C CNN
F 3 "~" H 5950 6850 60  0000 C CNN
	1    5950 6850
	-1   0    0    -1  
$EndComp
$Comp
L GND #PWR25
U 1 1 557CD0FD
P 7200 5650
F 0 "#PWR25" H 7200 5650 30  0001 C CNN
F 1 "GND" H 7200 5580 30  0001 C CNN
F 2 "" H 7200 5650 60  0000 C CNN
F 3 "" H 7200 5650 60  0000 C CNN
	1    7200 5650
	1    0    0    -1  
$EndComp
$Comp
L R-RESCUE-forthEx R12
U 1 1 557F975C
P 6300 5300
F 0 "R12" V 6380 5300 40  0000 C CNN
F 1 "1K" V 6307 5301 40  0000 C CNN
F 2 "~" V 6230 5300 30  0000 C CNN
F 3 "~" H 6300 5300 30  0000 C CNN
	1    6300 5300
	1    0    0    -1  
$EndComp
Text GLabel 4800 3650 0    39   Input ~ 0
Vidout
Text GLabel 4000 6850 0    39   Input ~ 0
Vidout
$Comp
L GND #PWR29
U 1 1 55FA1459
P 9350 5800
F 0 "#PWR29" H 9350 5800 30  0001 C CNN
F 1 "GND" H 9350 5730 30  0001 C CNN
F 2 "" H 9350 5800 60  0000 C CNN
F 3 "" H 9350 5800 60  0000 C CNN
	1    9350 5800
	1    0    0    -1  
$EndComp
$Comp
L C-RESCUE-forthEx C14
U 1 1 55FA145F
P 10700 5300
F 0 "C14" H 10700 5400 40  0000 L CNN
F 1 "100nF" H 10706 5215 40  0000 L CNN
F 2 "~" H 10738 5150 30  0000 C CNN
F 3 "~" H 10700 5300 60  0000 C CNN
	1    10700 5300
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR31
U 1 1 55FA1465
P 10900 5450
F 0 "#PWR31" H 10900 5450 30  0001 C CNN
F 1 "GND" H 10900 5380 30  0001 C CNN
F 2 "" H 10900 5450 60  0000 C CNN
F 3 "" H 10900 5450 60  0000 C CNN
	1    10900 5450
	1    0    0    -1  
$EndComp
Text GLabel 8850 5300 0    39   Input ~ 0
~SS2
Text GLabel 8850 5400 0    39   Input ~ 0
MISO
Text GLabel 10550 5600 2    39   Input ~ 0
MOSI
Text GLabel 10550 5500 2    39   Input ~ 0
SCLK
$Comp
L 23LC512 U5
U 1 1 55FA1475
P 9850 5500
F 0 "U5" H 9850 5300 60  0000 C CNN
F 1 "23LC1024" H 9850 5800 60  0000 C CNN
F 2 "" H 9850 5500 60  0000 C CNN
F 3 "" H 9850 5500 60  0000 C CNN
	1    9850 5500
	1    0    0    -1  
$EndComp
$Comp
L R-RESCUE-forthEx R16
U 1 1 55FA147B
P 9000 5000
F 0 "R16" V 9080 5000 40  0000 C CNN
F 1 "10k" V 9007 5001 40  0000 C CNN
F 2 "~" V 8930 5000 30  0000 C CNN
F 3 "~" H 9000 5000 30  0000 C CNN
	1    9000 5000
	1    0    0    -1  
$EndComp
Text GLabel 9250 4500 1    39   Input ~ 0
+3,3V
Text GLabel 6850 3750 2    39   Input ~ 0
~SS2
$Comp
L GND #PWR5
U 1 1 5600DB37
P 2700 1350
F 0 "#PWR5" H 2700 1350 30  0001 C CNN
F 1 "GND" H 2700 1280 30  0001 C CNN
F 2 "" H 2700 1350 60  0000 C CNN
F 3 "" H 2700 1350 60  0000 C CNN
	1    2700 1350
	1    0    0    -1  
$EndComp
$Comp
L R-RESCUE-forthEx R9
U 1 1 5601461A
P 5050 4600
F 0 "R9" V 5130 4600 40  0000 C CNN
F 1 "4k7" V 5057 4601 40  0000 C CNN
F 2 "~" V 4980 4600 30  0000 C CNN
F 3 "~" H 5050 4600 30  0000 C CNN
	1    5050 4600
	1    0    0    -1  
$EndComp
$Comp
L C-RESCUE-forthEx C9
U 1 1 5601470A
P 5050 5250
F 0 "C9" H 5050 5350 40  0000 L CNN
F 1 "10nF" H 5056 5165 40  0000 L CNN
F 2 "~" H 5088 5100 30  0000 C CNN
F 3 "~" H 5050 5250 60  0000 C CNN
	1    5050 5250
	1    0    0    -1  
$EndComp
$Comp
L C-RESCUE-forthEx C10
U 1 1 56014795
P 5950 5250
F 0 "C10" H 5950 5350 40  0000 L CNN
F 1 "22nF" H 5956 5165 40  0000 L CNN
F 2 "~" H 5988 5100 30  0000 C CNN
F 3 "~" H 5950 5250 60  0000 C CNN
	1    5950 5250
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR21
U 1 1 56014C24
P 5950 5500
F 0 "#PWR21" H 5950 5500 30  0001 C CNN
F 1 "GND" H 5950 5430 30  0001 C CNN
F 2 "" H 5950 5500 60  0000 C CNN
F 3 "" H 5950 5500 60  0000 C CNN
	1    5950 5500
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR20
U 1 1 56014C57
P 5050 5500
F 0 "#PWR20" H 5050 5500 30  0001 C CNN
F 1 "GND" H 5050 5430 30  0001 C CNN
F 2 "" H 5050 5500 60  0000 C CNN
F 3 "" H 5050 5500 60  0000 C CNN
	1    5050 5500
	1    0    0    -1  
$EndComp
$Comp
L DIODESCH D3
U 1 1 56081043
P 4300 6850
F 0 "D3" H 4300 6950 50  0000 C CNN
F 1 "1N6263" H 4300 6750 50  0000 C CNN
F 2 "" H 4300 6850 60  0000 C CNN
F 3 "" H 4300 6850 60  0000 C CNN
	1    4300 6850
	1    0    0    -1  
$EndComp
$Comp
L PIC24FJ64GA002 U3
U 1 1 5612D809
P 6000 3750
F 0 "U3" H 5950 3050 60  0000 C CNN
F 1 "PIC24EP512GP202" H 5950 4550 60  0000 C CNN
F 2 "" H 6000 3750 60  0000 C CNN
F 3 "" H 6000 3750 60  0000 C CNN
	1    6000 3750
	1    0    0    -1  
$EndComp
$Comp
L NPN Q2
U 1 1 5613BF34
P 2950 6700
F 0 "Q2" H 2950 6550 50  0000 R CNN
F 1 "2N3904" H 2950 6850 50  0000 R CNN
F 2 "" H 2950 6700 60  0000 C CNN
F 3 "" H 2950 6700 60  0000 C CNN
	1    2950 6700
	1    0    0    -1  
$EndComp
$Comp
L R-RESCUE-forthEx R2
U 1 1 5613C08F
P 2350 6700
F 0 "R2" V 2430 6700 50  0000 C CNN
F 1 "47K" V 2357 6701 50  0000 C CNN
F 2 "" V 2280 6700 30  0000 C CNN
F 3 "" H 2350 6700 30  0000 C CNN
	1    2350 6700
	0    1    1    0   
$EndComp
$Comp
L PNP Q1
U 1 1 5613F18D
P 1950 5700
F 0 "Q1" H 1950 5550 50  0000 R CNN
F 1 "2N3906" H 1950 5850 50  0000 R CNN
F 2 "" H 1950 5700 60  0000 C CNN
F 3 "" H 1950 5700 60  0000 C CNN
	1    1950 5700
	-1   0    0    1   
$EndComp
$Comp
L GND #PWR8
U 1 1 5613F3E7
P 3050 7050
F 0 "#PWR8" H 3050 7050 30  0001 C CNN
F 1 "GND" H 3050 6980 30  0001 C CNN
F 2 "" H 3050 7050 60  0000 C CNN
F 3 "" H 3050 7050 60  0000 C CNN
	1    3050 7050
	1    0    0    -1  
$EndComp
$Comp
L R-RESCUE-forthEx R4
U 1 1 5613F420
P 3050 6200
F 0 "R4" V 3130 6200 50  0000 C CNN
F 1 "10k" V 3057 6201 50  0000 C CNN
F 2 "" V 2980 6200 30  0000 C CNN
F 3 "" H 3050 6200 30  0000 C CNN
	1    3050 6200
	-1   0    0    1   
$EndComp
$Comp
L R-RESCUE-forthEx R1
U 1 1 5613F63B
P 1850 6250
F 0 "R1" V 1930 6250 50  0000 C CNN
F 1 "1K5" V 1857 6251 50  0000 C CNN
F 2 "" V 1780 6250 30  0000 C CNN
F 3 "" H 1850 6250 30  0000 C CNN
	1    1850 6250
	-1   0    0    1   
$EndComp
$Comp
L R-RESCUE-forthEx R3
U 1 1 5613F821
P 2500 5700
F 0 "R3" V 2580 5700 50  0000 C CNN
F 1 "10K" V 2507 5701 50  0000 C CNN
F 2 "" V 2430 5700 30  0000 C CNN
F 3 "" H 2500 5700 30  0000 C CNN
	1    2500 5700
	0    1    1    0   
$EndComp
Text GLabel 3250 6450 2    39   Input ~ 0
RX
Text GLabel 2800 5700 2    39   Input ~ 0
TX
Text GLabel 3050 5850 1    39   Input ~ 0
+3,3V
Text GLabel 1850 5400 1    39   Input ~ 0
+3,3V
Text GLabel 900  6700 0    39   Input ~ 0
RS232-RX
Text GLabel 1600 5900 1    39   Input ~ 0
RS232-TX
Text GLabel 6850 3650 2    39   Input ~ 0
TX
Text GLabel 6850 3550 2    39   Input ~ 0
RX
Text Notes 7050 3650 0    39   ~ 0
UART
Text Notes 2300 7350 0    39   ~ 0
RS232\nconverter
NoConn ~ 4200 950 
$Comp
L LM7805CT U2
U 1 1 5808A813
P 3200 900
F 0 "U2" H 3000 1100 50  0000 C CNN
F 1 "LM7805CT" H 3200 1100 50  0000 L CNN
F 2 "TO-220" H 3200 1000 50  0000 C CIN
F 3 "" H 3200 900 50  0000 C CNN
	1    3200 900 
	-1   0    0    -1  
$EndComp
$Comp
L GND #PWR11
U 1 1 5808AF37
P 3200 1250
F 0 "#PWR11" H 3200 1250 30  0001 C CNN
F 1 "GND" H 3200 1180 30  0001 C CNN
F 2 "" H 3200 1250 60  0000 C CNN
F 3 "" H 3200 1250 60  0000 C CNN
	1    3200 1250
	1    0    0    -1  
$EndComp
$Comp
L C-RESCUE-forthEx C5
U 1 1 5808B119
P 3600 1050
F 0 "C5" H 3600 1150 40  0000 L CNN
F 1 "220nF" H 3606 965 40  0000 L CNN
F 2 "~" H 3638 900 30  0000 C CNN
F 3 "~" H 3600 1050 60  0000 C CNN
	1    3600 1050
	1    0    0    -1  
$EndComp
Text GLabel 2400 800  1    39   Input ~ 0
+5V
$Comp
L SD_Card CON1
U 1 1 5808E7FC
P 1650 4000
F 0 "CON1" H 1000 4550 50  0000 C CNN
F 1 "SD_Card" H 2250 3450 50  0000 C CNN
F 2 "10067847-001" H 1850 4350 50  0000 C CNN
F 3 "" H 1650 4000 50  0000 C CNN
	1    1650 4000
	-1   0    0    1   
$EndComp
Text GLabel 7700 3450 2    39   Input ~ 0
CD
Text GLabel 750  4200 0    39   Input ~ 0
CD
$Comp
L GND #PWR7
U 1 1 5808F945
P 2750 4650
F 0 "#PWR7" H 2750 4650 30  0001 C CNN
F 1 "GND" H 2750 4580 30  0001 C CNN
F 2 "" H 2750 4650 60  0000 C CNN
F 3 "" H 2750 4650 60  0000 C CNN
	1    2750 4650
	1    0    0    -1  
$EndComp
Text GLabel 2550 4000 2    39   Input ~ 0
+Vsdc
Text GLabel 4850 3550 0    39   Input ~ 0
~SS3
Text GLabel 2550 3900 2    39   Input ~ 0
SCLK
Text GLabel 2550 4200 2    39   Input ~ 0
MOSI
Text GLabel 2550 3700 2    39   Input ~ 0
MISO
Text GLabel 2550 4300 2    39   Input ~ 0
~SS3
$Comp
L F_Small F1
U 1 1 5807E553
P 3900 850
F 0 "F1" H 3860 910 50  0000 L CNN
F 1 "500mA" H 3780 790 50  0000 L CNN
F 2 "" H 3900 850 50  0000 C CNN
F 3 "" H 3900 850 50  0000 C CNN
	1    3900 850 
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR13
U 1 1 5807E91E
P 3600 1300
F 0 "#PWR13" H 3600 1300 30  0001 C CNN
F 1 "GND" H 3600 1230 30  0001 C CNN
F 2 "" H 3600 1300 60  0000 C CNN
F 3 "" H 3600 1300 60  0000 C CNN
	1    3600 1300
	1    0    0    -1  
$EndComp
Text GLabel 9250 2750 1    39   Input ~ 0
+3,3V
$Sheet
S 8550 1250 1600 1000
U 5872D85C
F0 "ps2_rs232" 59
F1 "ps2_rs232.sch" 59
F2 "+5v" U L 8550 1700 59 
F3 "send" O L 8550 1950 59 
F4 "~REBOOT" O L 8550 2100 59 
F5 "~HRST" I L 8550 1400 59 
$EndSheet
Text GLabel 8350 1700 0    59   Input ~ 0
+5V
$Comp
L D D4
U 1 1 58736079
P 7900 3050
F 0 "D4" H 7900 3150 50  0000 C CNN
F 1 "1N4148" H 7900 2950 50  0000 C CNN
F 2 "" H 7900 3050 50  0000 C CNN
F 3 "" H 7900 3050 50  0000 C CNN
	1    7900 3050
	0    1    1    0   
$EndComp
Text Notes 7750 7500 2    59   ~ 0
forthex
Text Notes 7200 7000 0    59   ~ 0
ForthEx\nForth explorer computer\nCopyright, Jacques Deschenes, 2016,2017\nlicence: CC-BY_SA-V3.0
$Comp
L RJ12 J3
U 1 1 5873B6D8
P 950 5400
F 0 "J3" H 1150 5900 50  0000 C CNN
F 1 "RJ12" H 800 5900 50  0000 C CNN
F 2 "" H 950 5400 50  0000 C CNN
F 3 "" H 950 5400 50  0000 C CNN
	1    950  5400
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR1
U 1 1 5873C0B4
P 1150 6050
F 0 "#PWR1" H 1150 5800 50  0001 C CNN
F 1 "GND" H 1150 5900 50  0000 C CNN
F 2 "" H 1150 6050 50  0000 C CNN
F 3 "" H 1150 6050 50  0000 C CNN
	1    1150 6050
	1    0    0    -1  
$EndComp
NoConn ~ 1400 4750
NoConn ~ 1400 4850
NoConn ~ 1250 5850
NoConn ~ 1050 5850
NoConn ~ 750  5850
$Comp
L R R14
U 1 1 5873F621
P 5550 6500
F 0 "R14" V 5630 6500 50  0000 C CNN
F 1 "2k2" V 5550 6500 50  0000 C CNN
F 2 "" V 5480 6500 50  0000 C CNN
F 3 "" H 5550 6500 50  0000 C CNN
	1    5550 6500
	-1   0    0    1   
$EndComp
Wire Wire Line
	6300 5550 6300 5700
Connection ~ 5350 6850
Wire Wire Line
	5800 5050 6850 5050
Wire Wire Line
	5350 6150 5350 6250
Wire Wire Line
	5350 6750 5350 6850
Wire Wire Line
	4850 4050 5200 4050
Wire Wire Line
	5050 2250 5050 3050
Wire Wire Line
	4700 3050 5200 3050
Wire Wire Line
	4200 3050 3900 3050
Wire Wire Line
	3900 3050 3900 3150
Wire Wire Line
	3600 3100 3900 3100
Connection ~ 3900 3100
Wire Wire Line
	3400 3300 3400 3650
Wire Wire Line
	3900 3550 3900 3650
Wire Wire Line
	5000 3350 5000 2800
Wire Wire Line
	5000 2800 4750 2800
Wire Wire Line
	4750 2800 4750 2250
Wire Wire Line
	4950 3450 4950 2850
Wire Wire Line
	4950 2850 4650 2850
Wire Wire Line
	4650 2850 4650 2250
Wire Wire Line
	4850 2250 4850 2550
Wire Wire Line
	3900 2250 3900 2550
Wire Wire Line
	4950 2400 4950 2250
Connection ~ 3900 2400
Wire Wire Line
	6850 2400 6850 3050
Connection ~ 4950 2400
Wire Wire Line
	7400 2700 7400 2900
Wire Wire Line
	7000 2700 6850 2700
Connection ~ 6850 2700
Wire Wire Line
	6700 3150 7300 3150
Wire Wire Line
	7300 3150 7300 2850
Connection ~ 7400 2850
Wire Wire Line
	4500 4650 4500 4750
Wire Wire Line
	4350 4250 5200 4250
Wire Wire Line
	7650 3850 7650 4200
Wire Wire Line
	7650 3850 7500 3850
Wire Wire Line
	7100 3850 6700 3850
Connection ~ 7650 4050
Connection ~ 6850 2400
Wire Wire Line
	3100 4500 3100 4650
Wire Wire Line
	3700 4500 3700 4650
Wire Wire Line
	10400 2900 10400 3650
Wire Wire Line
	10400 3550 10500 3550
Wire Wire Line
	10900 3550 10900 3700
Wire Wire Line
	6850 4350 6700 4350
Wire Wire Line
	8850 3550 9350 3550
Wire Wire Line
	8850 3650 9350 3650
Wire Wire Line
	10550 3850 10400 3850
Wire Wire Line
	10550 3750 10400 3750
Connection ~ 10400 3550
Wire Wire Line
	1700 2800 1700 3150
Wire Wire Line
	1700 1400 1700 2400
Wire Wire Line
	7200 4050 7650 4050
Wire Wire Line
	7200 4050 7200 3950
Wire Wire Line
	7200 3950 6700 3950
Wire Wire Line
	6700 4150 6850 4150
Wire Wire Line
	6700 4250 6850 4250
Wire Wire Line
	6850 4050 6700 4050
Wire Wire Line
	9250 3500 9250 3550
Connection ~ 9250 3550
Wire Wire Line
	4900 3750 5200 3750
Wire Wire Line
	3700 4100 3700 3950
Wire Wire Line
	3700 3950 5200 3950
Wire Wire Line
	3100 4100 3100 3750
Wire Wire Line
	3100 3750 4400 3750
Wire Wire Line
	4400 3750 4400 3850
Wire Wire Line
	4400 3850 5200 3850
Wire Wire Line
	3100 2450 3100 2400
Wire Wire Line
	3100 2950 3100 3050
Wire Wire Line
	3100 3450 3100 3550
Wire Wire Line
	2000 1400 1800 1400
Wire Wire Line
	4200 1050 4200 1300
Wire Wire Line
	5950 7350 5950 7450
Wire Wire Line
	7200 5550 7200 5650
Wire Wire Line
	7300 2850 7400 2850
Wire Wire Line
	5000 3350 5200 3350
Wire Wire Line
	9250 2750 9250 3000
Wire Wire Line
	9000 2900 10400 2900
Connection ~ 9250 2900
Wire Wire Line
	9000 2900 9000 3000
Wire Wire Line
	9000 3500 9000 3650
Connection ~ 9000 3650
Wire Wire Line
	4800 3650 5200 3650
Wire Wire Line
	4500 6850 4700 6850
Wire Wire Line
	6850 3050 6700 3050
Connection ~ 5050 3050
Wire Wire Line
	9350 3850 9350 4050
Wire Wire Line
	9350 3750 9150 3750
Wire Wire Line
	9150 3750 9150 2900
Connection ~ 9150 2900
Wire Wire Line
	10400 4650 10400 5400
Wire Wire Line
	10400 5300 10500 5300
Wire Wire Line
	10900 5300 10900 5450
Wire Wire Line
	8850 5300 9350 5300
Wire Wire Line
	8850 5400 9350 5400
Wire Wire Line
	10550 5600 10400 5600
Wire Wire Line
	10550 5500 10400 5500
Connection ~ 10400 5300
Wire Wire Line
	9000 4650 10400 4650
Connection ~ 9250 4650
Wire Wire Line
	9350 5600 9350 5800
Wire Wire Line
	9350 5500 9150 5500
Wire Wire Line
	9150 5500 9150 4650
Connection ~ 9150 4650
Wire Wire Line
	6700 3750 6850 3750
Connection ~ 3100 2400
Wire Wire Line
	2700 900  2700 850 
Connection ~ 2700 850 
Wire Wire Line
	2700 1300 2700 1350
Wire Wire Line
	1600 1400 1600 1500
Wire Wire Line
	9000 4650 9000 4750
Wire Wire Line
	9000 5250 9000 5300
Connection ~ 9000 5300
Wire Wire Line
	9250 4500 9250 4650
Wire Wire Line
	5200 4350 5050 4350
Connection ~ 6300 5050
Wire Wire Line
	5050 4850 5050 5050
Wire Wire Line
	5050 5050 5300 5050
Wire Wire Line
	5050 5450 5050 5500
Wire Wire Line
	5950 5450 5950 5500
Wire Wire Line
	6700 3250 7900 3250
Wire Wire Line
	7550 3100 7550 3250
Connection ~ 7550 3250
Wire Wire Line
	7550 2400 7550 2600
Connection ~ 7550 2400
Wire Wire Line
	4000 6850 4100 6850
Wire Wire Line
	900  6700 2100 6700
Wire Wire Line
	2600 6700 2750 6700
Wire Wire Line
	3050 6900 3050 7050
Wire Wire Line
	3050 6450 3050 6500
Wire Wire Line
	2250 5700 2150 5700
Wire Wire Line
	1850 5900 1850 6000
Wire Wire Line
	3250 6450 3050 6450
Wire Wire Line
	3050 5850 3050 5950
Wire Wire Line
	2750 5700 2800 5700
Wire Wire Line
	1850 5400 1850 5500
Wire Wire Line
	850  5950 1850 5950
Connection ~ 1850 5950
Wire Wire Line
	6850 3550 6700 3550
Wire Wire Line
	6850 3650 6700 3650
Connection ~ 1700 2300
Wire Wire Line
	2000 850  2800 850 
Wire Wire Line
	2000 850  2000 1400
Wire Wire Line
	3200 1150 3200 1250
Wire Wire Line
	2400 800  2400 850 
Connection ~ 2400 850 
Wire Wire Line
	6700 3450 7700 3450
Wire Wire Line
	2750 3800 2750 4650
Wire Wire Line
	2750 3800 2550 3800
Wire Wire Line
	2550 4100 2750 4100
Connection ~ 2750 4100
Wire Wire Line
	3800 850  3600 850 
Wire Wire Line
	4000 850  4200 850 
Wire Wire Line
	3600 1250 3600 1300
Wire Wire Line
	8350 1700 8550 1700
Wire Wire Line
	2800 2400 8450 2400
Wire Wire Line
	7900 3250 7900 3200
Wire Wire Line
	7900 2900 7900 1950
Wire Wire Line
	7900 1950 8550 1950
Wire Wire Line
	1600 5900 1600 5950
Wire Wire Line
	950  6700 950  5850
Wire Wire Line
	850  5950 850  5850
Connection ~ 1600 5950
Wire Wire Line
	1150 5850 1150 6050
Wire Wire Line
	5200 6850 5600 6850
Wire Wire Line
	8250 2100 8550 2100
$Comp
L R-RESCUE-forthEx R23
U 1 1 58742A36
P 5200 2650
F 0 "R23" V 5280 2650 40  0000 C CNN
F 1 "10K" V 5207 2651 40  0000 C CNN
F 2 "~" V 5130 2650 30  0000 C CNN
F 3 "~" H 5200 2650 30  0000 C CNN
	1    5200 2650
	-1   0    0    1   
$EndComp
Connection ~ 5200 2400
Wire Wire Line
	5200 2900 5200 3150
Wire Wire Line
	5200 2950 5350 2950
Wire Wire Line
	5350 2950 5350 1400
Wire Wire Line
	5350 1400 8550 1400
Connection ~ 5200 2950
$Comp
L R-RESCUE-forthEx R24
U 1 1 587A4268
P 7700 2850
F 0 "R24" V 7780 2850 40  0000 C CNN
F 1 "10K" V 7707 2851 40  0000 C CNN
F 2 "~" V 7630 2850 30  0000 C CNN
F 3 "~" H 7700 2850 30  0000 C CNN
	1    7700 2850
	-1   0    0    1   
$EndComp
Wire Wire Line
	7700 2400 7700 2600
Wire Wire Line
	7700 3450 7700 3100
$Comp
L R-RESCUE-forthEx R25
U 1 1 587AB52E
P 4400 2650
F 0 "R25" V 4480 2650 40  0000 C CNN
F 1 "10K" V 4407 2651 40  0000 C CNN
F 2 "~" V 4330 2650 30  0000 C CNN
F 3 "~" H 4400 2650 30  0000 C CNN
	1    4400 2650
	-1   0    0    1   
$EndComp
Connection ~ 4400 2400
Wire Wire Line
	4400 2900 4850 2900
Wire Wire Line
	4850 2900 4850 3550
Wire Wire Line
	4850 3550 5200 3550
$Comp
L D D7
U 1 1 587CE66F
P 3650 2800
F 0 "D7" H 3650 2900 50  0000 C CNN
F 1 "1N4148" H 3650 2700 50  0000 C CNN
F 2 "" H 3650 2800 50  0000 C CNN
F 3 "" H 3650 2800 50  0000 C CNN
	1    3650 2800
	0    1    1    0   
$EndComp
Wire Wire Line
	3650 2650 3650 2400
Connection ~ 3650 2400
Wire Wire Line
	3650 2950 3650 3100
Connection ~ 3650 3100
$Comp
L D D6
U 1 1 58897471
P 8250 3050
F 0 "D6" H 8250 3150 50  0000 C CNN
F 1 "1N4148" H 8250 2950 50  0000 C CNN
F 2 "" H 8250 3050 50  0000 C CNN
F 3 "" H 8250 3050 50  0000 C CNN
	1    8250 3050
	0    1    1    0   
$EndComp
Wire Wire Line
	8250 2100 8250 2900
Wire Wire Line
	8250 3200 8250 3350
Wire Wire Line
	6700 3350 8450 3350
$Comp
L R-RESCUE-forthEx R18
U 1 1 588977AF
P 8450 2850
F 0 "R18" V 8530 2850 40  0000 C CNN
F 1 "10K" V 8457 2851 40  0000 C CNN
F 2 "~" V 8380 2850 30  0000 C CNN
F 3 "~" H 8450 2850 30  0000 C CNN
	1    8450 2850
	-1   0    0    1   
$EndComp
Wire Wire Line
	8450 2400 8450 2600
Connection ~ 7700 2400
Wire Wire Line
	8450 3350 8450 3100
Connection ~ 8250 3350
$Comp
L L L1
U 1 1 58E82954
P 2550 2850
F 0 "L1" V 2500 2850 50  0000 C CNN
F 1 "15µH" V 2625 2850 50  0000 C CNN
F 2 "" H 2550 2850 50  0001 C CNN
F 3 "" H 2550 2850 50  0001 C CNN
	1    2550 2850
	0    -1   -1   0   
$EndComp
$Comp
L CAPAPOL C18
U 1 1 58E84A23
P 2400 3050
F 0 "C18" H 2450 3150 40  0000 L CNN
F 1 "4,7µF" H 2450 2950 40  0000 L CNN
F 2 "~" H 2500 2900 30  0000 C CNN
F 3 "~" H 2400 3050 300 0000 C CNN
	1    2400 3050
	1    0    0    -1  
$EndComp
$Comp
L CAPAPOL C19
U 1 1 58E84B29
P 2700 3050
F 0 "C19" H 2750 3150 40  0000 L CNN
F 1 "220µF" H 2750 2950 40  0000 L CNN
F 2 "~" H 2800 2900 30  0000 C CNN
F 3 "~" H 2700 3050 300 0000 C CNN
	1    2700 3050
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR4
U 1 1 58E84D59
P 2400 3250
F 0 "#PWR4" H 2400 3250 30  0001 C CNN
F 1 "GND" H 2400 3180 30  0001 C CNN
F 2 "" H 2400 3250 60  0000 C CNN
F 3 "" H 2400 3250 60  0000 C CNN
	1    2400 3250
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR6
U 1 1 58E84FE5
P 2700 3250
F 0 "#PWR6" H 2700 3250 30  0001 C CNN
F 1 "GND" H 2700 3180 30  0001 C CNN
F 2 "" H 2700 3250 60  0000 C CNN
F 3 "" H 2700 3250 60  0000 C CNN
	1    2700 3250
	1    0    0    -1  
$EndComp
Text GLabel 2350 2850 0    39   Input ~ 0
+Vsdc
Wire Wire Line
	2350 2850 2400 2850
Wire Wire Line
	2700 2850 2700 2700
Wire Wire Line
	1700 2300 1800 2300
Wire Wire Line
	2700 2700 2800 2700
Wire Wire Line
	2800 2700 2800 2400
NoConn ~ 5200 3250
Wire Wire Line
	5550 6650 5550 6850
Connection ~ 5550 6850
Text GLabel 5550 6150 1    39   Input ~ 0
BLKLVL
Wire Wire Line
	5550 6150 5550 6350
Text GLabel 4850 4150 0    39   Input ~ 0
BLKLVL
Wire Wire Line
	4850 4150 5200 4150
Wire Wire Line
	4950 3450 5200 3450
Text Notes 7050 6450 0    39   ~ 0
NOTE:  Le standard NTSC défini un seuil de noir qui correspond au\n BACKPORCH et FRONTPORCH. Il semble que les moniteurs LCD acceptent le\n signal NTSC sans l'ajout de ce signal. le signal BLKLVL est donc optionnel et\n la broche 12 peut-être libérée et la résistance R14 supprimée.
$Sheet
S 6450 650  1300 600 
U 593A9E53
F0 "alim_5neg" 39
F1 "alim_5neg.sch" 39
F2 "+5v" I L 6450 750 39 
F3 "-4v" O L 6450 900 39 
F4 "gnd" U L 6450 1150 39 
$EndSheet
$Comp
L GND #PWR23
U 1 1 593AA61C
P 6300 1200
F 0 "#PWR23" H 6300 1200 30  0001 C CNN
F 1 "GND" H 6300 1130 30  0001 C CNN
F 2 "" H 6300 1200 60  0000 C CNN
F 3 "" H 6300 1200 60  0000 C CNN
	1    6300 1200
	1    0    0    -1  
$EndComp
Wire Wire Line
	6300 1200 6300 1150
Wire Wire Line
	6300 1150 6450 1150
Text GLabel 6300 750  0    39   Input ~ 0
+5V
Wire Wire Line
	6300 750  6450 750 
Text GLabel 6300 900  0    39   Input ~ 0
-4V
Wire Wire Line
	6300 900  6450 900 
Connection ~ 950  6700
Text GLabel 1750 6500 0    39   Input ~ 0
-4V
Wire Wire Line
	1750 6500 1850 6500
$EndSCHEMATC
