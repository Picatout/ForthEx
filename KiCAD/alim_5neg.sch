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
Sheet 3 3
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L TLC555 U7
U 1 1 593B0F31
P 5750 3100
F 0 "U7" H 5350 3450 50  0000 L CNN
F 1 "TLC555" H 5350 2750 50  0000 L CNN
F 2 "" H 5750 3100 50  0001 C CNN
F 3 "" H 5750 3100 50  0001 C CNN
	1    5750 3100
	1    0    0    -1  
$EndComp
$Comp
L DIODESCH D1
U 1 1 593B0FFB
P 6950 3100
F 0 "D1" H 6950 3200 50  0000 C CNN
F 1 "1N5817" H 6950 3000 50  0000 C CNN
F 2 "" H 6950 3100 60  0000 C CNN
F 3 "" H 6950 3100 60  0000 C CNN
	1    6950 3100
	0    1    1    0   
$EndComp
$Comp
L DIODESCH D9
U 1 1 593B1032
P 7300 2900
F 0 "D9" H 7300 3000 50  0000 C CNN
F 1 "1N5817" H 7300 2800 50  0000 C CNN
F 2 "" H 7300 2900 60  0000 C CNN
F 3 "" H 7300 2900 60  0000 C CNN
	1    7300 2900
	-1   0    0    1   
$EndComp
$Comp
L R R28
U 1 1 593B10CA
P 6550 3600
F 0 "R28" V 6630 3600 50  0000 C CNN
F 1 "10K" V 6550 3600 50  0000 C CNN
F 2 "" V 6480 3600 50  0001 C CNN
F 3 "" H 6550 3600 50  0001 C CNN
	1    6550 3600
	-1   0    0    1   
$EndComp
$Comp
L R R27
U 1 1 593B10FB
P 6250 2650
F 0 "R27" V 6330 2650 50  0000 C CNN
F 1 "1K" V 6250 2650 50  0000 C CNN
F 2 "" V 6180 2650 50  0001 C CNN
F 3 "" H 6250 2650 50  0001 C CNN
	1    6250 2650
	1    0    0    -1  
$EndComp
$Comp
L C C21
U 1 1 593B1170
P 6550 4000
F 0 "C21" H 6575 4100 50  0000 L CNN
F 1 "100pF" H 6575 3900 50  0000 L CNN
F 2 "" H 6588 3850 50  0001 C CNN
F 3 "" H 6550 4000 50  0001 C CNN
	1    6550 4000
	-1   0    0    1   
$EndComp
$Comp
L C C20
U 1 1 593B1412
P 4650 3250
F 0 "C20" H 4675 3350 50  0000 L CNN
F 1 "100nF" H 4675 3150 50  0000 L CNN
F 2 "" H 4688 3100 50  0001 C CNN
F 3 "" H 4650 3250 50  0001 C CNN
	1    4650 3250
	-1   0    0    1   
$EndComp
Text HLabel 4100 2500 0    39   Input ~ 0
+5V
Wire Wire Line
	4900 3850 6550 3850
Wire Wire Line
	4900 2900 5250 2900
Wire Wire Line
	4650 3100 5250 3100
Wire Wire Line
	4100 2500 6250 2500
Wire Wire Line
	5750 2500 5750 2700
Wire Wire Line
	5250 3300 5200 3300
Wire Wire Line
	5200 3300 5200 2500
Connection ~ 5200 2500
Wire Wire Line
	6250 2900 6450 2900
Wire Wire Line
	6750 2900 7100 2900
Connection ~ 6950 2900
Wire Wire Line
	7500 2900 7800 2900
Wire Wire Line
	7650 2900 7650 3000
Wire Wire Line
	4650 3400 4650 3500
Wire Wire Line
	6950 3300 6950 3400
Wire Wire Line
	7650 3300 7650 3400
Wire Wire Line
	6550 4150 6550 4250
Wire Wire Line
	5750 3500 5750 3600
Text HLabel 7800 2900 2    39   Input ~ 0
-5V
Connection ~ 7650 2900
Text Notes 7450 7500 0    39   ~ 0
ALIMENTATION -4VOLT\n
Wire Wire Line
	6550 3850 6550 3750
Wire Wire Line
	6550 3450 6550 3100
Wire Wire Line
	6550 3100 6250 3100
Wire Wire Line
	6250 3300 6250 3850
Connection ~ 6250 3850
Wire Wire Line
	6250 3100 6250 2800
Connection ~ 5750 2500
Wire Wire Line
	4900 2900 4900 3850
$Comp
L CP C22
U 1 1 593B29FE
P 6600 2900
F 0 "C22" H 6625 3000 50  0000 L CNN
F 1 "22µF" H 6625 2800 50  0000 L CNN
F 2 "" H 6638 2750 50  0001 C CNN
F 3 "" H 6600 2900 50  0001 C CNN
	1    6600 2900
	0    -1   -1   0   
$EndComp
$Comp
L CP C23
U 1 1 593B2A35
P 7650 3150
F 0 "C23" H 7675 3250 50  0000 L CNN
F 1 "33µF" H 7675 3050 50  0000 L CNN
F 2 "" H 7688 3000 50  0001 C CNN
F 3 "" H 7650 3150 50  0001 C CNN
	1    7650 3150
	-1   0    0    1   
$EndComp
$Comp
L C C2
U 1 1 593B2B75
P 4350 2650
F 0 "C2" H 4375 2750 50  0000 L CNN
F 1 "1µF" H 4375 2550 50  0000 L CNN
F 2 "" H 4388 2500 50  0001 C CNN
F 3 "" H 4350 2650 50  0001 C CNN
	1    4350 2650
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR39
U 1 1 593B2BFD
P 4550 2850
F 0 "#PWR39" H 4550 2600 50  0001 C CNN
F 1 "GND" H 4550 2700 50  0000 C CNN
F 2 "" H 4550 2850 50  0001 C CNN
F 3 "" H 4550 2850 50  0001 C CNN
	1    4550 2850
	1    0    0    -1  
$EndComp
Wire Wire Line
	4550 2800 4550 2850
$Comp
L GND #PWR40
U 1 1 593B2CAB
P 4650 3500
F 0 "#PWR40" H 4650 3250 50  0001 C CNN
F 1 "GND" H 4650 3350 50  0000 C CNN
F 2 "" H 4650 3500 50  0001 C CNN
F 3 "" H 4650 3500 50  0001 C CNN
	1    4650 3500
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR42
U 1 1 593B2CD7
P 6550 4250
F 0 "#PWR42" H 6550 4000 50  0001 C CNN
F 1 "GND" H 6550 4100 50  0000 C CNN
F 2 "" H 6550 4250 50  0001 C CNN
F 3 "" H 6550 4250 50  0001 C CNN
	1    6550 4250
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR41
U 1 1 593B2D03
P 5750 3600
F 0 "#PWR41" H 5750 3350 50  0001 C CNN
F 1 "GND" H 5750 3450 50  0000 C CNN
F 2 "" H 5750 3600 50  0001 C CNN
F 3 "" H 5750 3600 50  0001 C CNN
	1    5750 3600
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR43
U 1 1 593B2D2F
P 6950 3400
F 0 "#PWR43" H 6950 3150 50  0001 C CNN
F 1 "GND" H 6950 3250 50  0000 C CNN
F 2 "" H 6950 3400 50  0001 C CNN
F 3 "" H 6950 3400 50  0001 C CNN
	1    6950 3400
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR44
U 1 1 593B2D5B
P 7650 3400
F 0 "#PWR44" H 7650 3150 50  0001 C CNN
F 1 "GND" H 7650 3250 50  0000 C CNN
F 2 "" H 7650 3400 50  0001 C CNN
F 3 "" H 7650 3400 50  0001 C CNN
	1    7650 3400
	1    0    0    -1  
$EndComp
$Comp
L C C?
U 1 1 593B2E41
P 4700 2650
F 0 "C?" H 4725 2750 50  0000 L CNN
F 1 "100nF" H 4725 2550 50  0000 L CNN
F 2 "" H 4738 2500 50  0001 C CNN
F 3 "" H 4700 2650 50  0001 C CNN
	1    4700 2650
	1    0    0    -1  
$EndComp
Wire Wire Line
	4350 2800 4700 2800
Connection ~ 4550 2800
Connection ~ 4350 2500
$EndSCHEMATC
