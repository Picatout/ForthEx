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
Sheet 4 4
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Text Notes 8100 7000 0    98   ~ 0
EEPROM enfichable\n128Ko
$Comp
L 25LC_EEPROM U4
U 1 1 5963C4C3
P 5950 3600
F 0 "U4" H 5650 3850 50  0000 L CNN
F 1 "25LC1024" H 6000 3850 50  0000 L CNN
F 2 "" H 5600 3550 50  0001 C CNN
F 3 "" H 5600 3550 50  0001 C CNN
	1    5950 3600
	1    0    0    -1  
$EndComp
Text HLabel 4700 3850 2    59   Input ~ 0
gnd
Text HLabel 4650 3350 2    59   Input ~ 0
+3,3V
Wire Wire Line
	5950 3100 5950 3300
Wire Wire Line
	5550 3100 5550 3600
Connection ~ 5950 3100
Connection ~ 5550 3500
$Comp
L CONN_01X06 J4
U 1 1 5963C7BF
P 4250 3600
F 0 "J4" H 4250 3950 50  0000 C CNN
F 1 "CONN_01X06" V 4350 3600 50  0000 C CNN
F 2 "" H 4250 3600 50  0001 C CNN
F 3 "" H 4250 3600 50  0001 C CNN
	1    4250 3600
	-1   0    0    1   
$EndComp
Wire Wire Line
	4450 3350 4650 3350
Wire Wire Line
	4450 3850 4700 3850
Wire Wire Line
	4600 3850 4600 4000
Wire Wire Line
	4600 4000 5950 4000
Wire Wire Line
	5950 4000 5950 3900
Connection ~ 4600 3850
Wire Wire Line
	4550 3350 4550 3100
Connection ~ 5550 3100
Connection ~ 4550 3350
Wire Wire Line
	4450 3750 5550 3750
Wire Wire Line
	5550 3750 5550 3700
Text HLabel 4650 3650 2    59   Input ~ 0
SCLK
Text HLabel 4650 3550 2    59   Input ~ 0
MOSI
Text HLabel 4650 3450 2    59   Input ~ 0
MISO
Wire Wire Line
	4450 3450 4650 3450
Wire Wire Line
	4450 3550 4650 3550
Wire Wire Line
	4450 3650 4650 3650
Text Label 6350 3600 0    39   ~ 0
MOSI
Text Label 6350 3700 0    39   ~ 0
MISO
Text Label 6350 3500 0    39   ~ 0
SCLK
Text Label 4450 3650 0    39   ~ 0
SCLK
Text Label 4450 3550 0    39   ~ 0
MOSI
Text Label 4450 3450 0    39   ~ 0
MISO
Wire Wire Line
	4550 3100 5950 3100
Text Notes 7600 7500 0    79   ~ 0
ForthEx\n
$EndSCHEMATC
