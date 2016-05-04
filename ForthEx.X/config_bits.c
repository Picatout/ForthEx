//;****************************************************************************
//; Copyright 2015, Jacques Deschênes
//; This file is part of ForthEx.
//;
//;     ForthEx is free software: you can redistribute it and/or modify
//;     it under the terms of the GNU General Public License as published by
//;     the Free Software Foundation, either version 3 of the License, or
//;     (at your option) any later version.
//;
//;     ForthEx is distributed in the hope that it will be useful,
//;     but WITHOUT ANY WARRANTY; without even the implied warranty of
//;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//;     GNU General Public License for more details.
//;
//;     You should have received a copy of the GNU General Public License
//;     along with ForthEx.  If not, see <http://www.gnu.org/licenses/>.
//;
//;****************************************************************************

// PIC24FJ64GA002 Configuration Bit Settings

// 'C' source line config statements
#include <xc.h>

// FICD
#pragma config ICS = PGD3               // ICD Communication Channel Select bits (Communicate on PGEC3 and PGED3)
#pragma config JTAGEN = OFF             // JTAG Enable bit (JTAG is disabled)

// FPOR
#pragma config ALTI2C1 = OFF            // Alternate I2C1 pins (I2C1 mapped to SDA1/SCL1 pins)
#pragma config ALTI2C2 = OFF            // Alternate I2C2 pins (I2C2 mapped to SDA2/SCL2 pins)
#pragma config WDTWIN = WIN25           // Watchdog Window Select bits (WDT Window is 25% of WDT period)

// FWDT
#pragma config WDTPOST = PS32768        // Watchdog Timer Postscaler bits (1:32,768)
#pragma config WDTPRE = PR32            // Watchdog Timer Prescaler bit (1:32)
#pragma config PLLKEN = OFF             // PLL Lock Enable bit (Clock switch will not wait for the PLL lock signal.)
#pragma config WINDIS = OFF             // Watchdog Timer Window Enable bit (Watchdog Timer in Non-Window mode)
#pragma config FWDTEN = OFF             // Watchdog Timer Enable bit (Watchdog timer enabled/disabled by user software)

// FOSC
#pragma config POSCMD = HS              // Primary Oscillator Mode Select bits (HS Crystal Oscillator Mode)
#pragma config OSCIOFNC = ON            // OSC2 Pin Function bit (OSC2 is general purpose digital I/O pin)
#pragma config IOL1WAY = ON             // Peripheral pin select configuration (Allow multiple reconfigurations)
#pragma config FCKSM = CSDCMD           // Clock Switching Mode bits (Both Clock switching and Fail-safe Clock Monitor are disabled)

// FOSCSEL
#pragma config FNOSC = PRIPLL           // Oscillator Source Selection (Primary Oscillator with PLL module (XT + PLL, HS + PLL, EC + PLL))
#pragma config IESO = ON                // Two-speed Oscillator Start-up Enable bit (Start up with user-selected oscillator source)

// FGS
#pragma config GWRP = OFF               // General Segment Write-Protect bit (General Segment may be written)
#pragma config GCP = OFF                // General Segment Code-Protect bit (General Segment Code protect is Disabled)

