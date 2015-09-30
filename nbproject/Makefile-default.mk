#
# Generated Makefile - do not edit!
#
# Edit the Makefile in the project folder instead (../Makefile). Each target
# has a -pre and a -post target defined where you can add customized code.
#
# This makefile implements configuration specific macros and targets.


# Include project Makefile
ifeq "${IGNORE_LOCAL}" "TRUE"
# do not include local makefile. User is passing all local related variables already
else
include Makefile
# Include makefile containing local settings
ifeq "$(wildcard nbproject/Makefile-local-default.mk)" "nbproject/Makefile-local-default.mk"
include nbproject/Makefile-local-default.mk
endif
endif

# Environment
MKDIR=mkdir -p
RM=rm -f 
MV=mv 
CP=cp 

# Macros
CND_CONF=default
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
IMAGE_TYPE=debug
OUTPUT_SUFFIX=elf
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=dist/${CND_CONF}/${IMAGE_TYPE}/ForthEx.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
else
IMAGE_TYPE=production
OUTPUT_SUFFIX=hex
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=dist/${CND_CONF}/${IMAGE_TYPE}/ForthEx.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
endif

# Object Directory
OBJECTDIR=build/${CND_CONF}/${IMAGE_TYPE}

# Distribution Directory
DISTDIR=dist/${CND_CONF}/${IMAGE_TYPE}

# Source Files Quoted if spaced
SOURCEFILES_QUOTED_IF_SPACED=main.s hardware.s config_bits.c TVout.S font.S ps2.s keyboard.s qwerty.s

# Object Files Quoted if spaced
OBJECTFILES_QUOTED_IF_SPACED=${OBJECTDIR}/main.o ${OBJECTDIR}/hardware.o ${OBJECTDIR}/config_bits.o ${OBJECTDIR}/TVout.o ${OBJECTDIR}/font.o ${OBJECTDIR}/ps2.o ${OBJECTDIR}/keyboard.o ${OBJECTDIR}/qwerty.o
POSSIBLE_DEPFILES=${OBJECTDIR}/main.o.d ${OBJECTDIR}/hardware.o.d ${OBJECTDIR}/config_bits.o.d ${OBJECTDIR}/TVout.o.d ${OBJECTDIR}/font.o.d ${OBJECTDIR}/ps2.o.d ${OBJECTDIR}/keyboard.o.d ${OBJECTDIR}/qwerty.o.d

# Object Files
OBJECTFILES=${OBJECTDIR}/main.o ${OBJECTDIR}/hardware.o ${OBJECTDIR}/config_bits.o ${OBJECTDIR}/TVout.o ${OBJECTDIR}/font.o ${OBJECTDIR}/ps2.o ${OBJECTDIR}/keyboard.o ${OBJECTDIR}/qwerty.o

# Source Files
SOURCEFILES=main.s hardware.s config_bits.c TVout.S font.S ps2.s keyboard.s qwerty.s


CFLAGS=
ASFLAGS=
LDLIBSOPTIONS=

############# Tool locations ##########################################
# If you copy a project from one host to another, the path where the  #
# compiler is installed may be different.                             #
# If you open this project with MPLAB X in the new host, this         #
# makefile will be regenerated and the paths will be corrected.       #
#######################################################################
# fixDeps replaces a bunch of sed/cat/printf statements that slow down the build
FIXDEPS=fixDeps

.build-conf:  ${BUILD_SUBPROJECTS}
ifneq ($(INFORMATION_MESSAGE), )
	@echo $(INFORMATION_MESSAGE)
endif
	${MAKE}  -f nbproject/Makefile-default.mk dist/${CND_CONF}/${IMAGE_TYPE}/ForthEx.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}

MP_PROCESSOR_OPTION=24FJ64GA002
MP_LINKER_FILE_OPTION=,--script=p24FJ64GA002.gld
# ------------------------------------------------------------------------------------
# Rules for buildStep: compile
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${OBJECTDIR}/config_bits.o: config_bits.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/config_bits.o.d 
	@${RM} ${OBJECTDIR}/config_bits.o 
	${MP_CC} $(MP_EXTRA_CC_PRE)  config_bits.c  -o ${OBJECTDIR}/config_bits.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -MMD -MF "${OBJECTDIR}/config_bits.o.d"      -g -D__DEBUG -D__MPLAB_DEBUGGER_PICKIT2=1    -omf=elf -save-temps=obj -O0 -msmart-io=1 -Wall -msfr-warn=off
	@${FIXDEPS} "${OBJECTDIR}/config_bits.o.d" $(SILENT)  -rsi ${MP_CC_DIR}../ 
	
else
${OBJECTDIR}/config_bits.o: config_bits.c  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/config_bits.o.d 
	@${RM} ${OBJECTDIR}/config_bits.o 
	${MP_CC} $(MP_EXTRA_CC_PRE)  config_bits.c  -o ${OBJECTDIR}/config_bits.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -MMD -MF "${OBJECTDIR}/config_bits.o.d"        -g -omf=elf -save-temps=obj -O0 -msmart-io=1 -Wall -msfr-warn=off
	@${FIXDEPS} "${OBJECTDIR}/config_bits.o.d" $(SILENT)  -rsi ${MP_CC_DIR}../ 
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: assemble
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${OBJECTDIR}/main.o: main.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/main.o.d 
	@${RM} ${OBJECTDIR}/main.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  main.s  -o ${OBJECTDIR}/main.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -D__DEBUG -D__MPLAB_DEBUGGER_PICKIT2=1  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/main.o.d",--defsym=__MPLAB_BUILD=1,--defsym=__ICD2RAM=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,--defsym=__MPLAB_DEBUGGER_PICKIT2=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/main.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/main.o.d"  $(SILENT)  -rsi ${MP_CC_DIR}../  
	
${OBJECTDIR}/hardware.o: hardware.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/hardware.o.d 
	@${RM} ${OBJECTDIR}/hardware.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  hardware.s  -o ${OBJECTDIR}/hardware.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -D__DEBUG -D__MPLAB_DEBUGGER_PICKIT2=1  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/hardware.o.d",--defsym=__MPLAB_BUILD=1,--defsym=__ICD2RAM=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,--defsym=__MPLAB_DEBUGGER_PICKIT2=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/hardware.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/hardware.o.d"  $(SILENT)  -rsi ${MP_CC_DIR}../  
	
${OBJECTDIR}/ps2.o: ps2.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ps2.o.d 
	@${RM} ${OBJECTDIR}/ps2.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  ps2.s  -o ${OBJECTDIR}/ps2.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -D__DEBUG -D__MPLAB_DEBUGGER_PICKIT2=1  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/ps2.o.d",--defsym=__MPLAB_BUILD=1,--defsym=__ICD2RAM=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,--defsym=__MPLAB_DEBUGGER_PICKIT2=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/ps2.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/ps2.o.d"  $(SILENT)  -rsi ${MP_CC_DIR}../  
	
${OBJECTDIR}/keyboard.o: keyboard.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/keyboard.o.d 
	@${RM} ${OBJECTDIR}/keyboard.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  keyboard.s  -o ${OBJECTDIR}/keyboard.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -D__DEBUG -D__MPLAB_DEBUGGER_PICKIT2=1  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/keyboard.o.d",--defsym=__MPLAB_BUILD=1,--defsym=__ICD2RAM=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,--defsym=__MPLAB_DEBUGGER_PICKIT2=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/keyboard.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/keyboard.o.d"  $(SILENT)  -rsi ${MP_CC_DIR}../  
	
${OBJECTDIR}/qwerty.o: qwerty.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/qwerty.o.d 
	@${RM} ${OBJECTDIR}/qwerty.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  qwerty.s  -o ${OBJECTDIR}/qwerty.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -D__DEBUG -D__MPLAB_DEBUGGER_PICKIT2=1  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/qwerty.o.d",--defsym=__MPLAB_BUILD=1,--defsym=__ICD2RAM=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,--defsym=__MPLAB_DEBUGGER_PICKIT2=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/qwerty.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/qwerty.o.d"  $(SILENT)  -rsi ${MP_CC_DIR}../  
	
else
${OBJECTDIR}/main.o: main.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/main.o.d 
	@${RM} ${OBJECTDIR}/main.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  main.s  -o ${OBJECTDIR}/main.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/main.o.d",--defsym=__MPLAB_BUILD=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/main.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/main.o.d"  $(SILENT)  -rsi ${MP_CC_DIR}../  
	
${OBJECTDIR}/hardware.o: hardware.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/hardware.o.d 
	@${RM} ${OBJECTDIR}/hardware.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  hardware.s  -o ${OBJECTDIR}/hardware.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/hardware.o.d",--defsym=__MPLAB_BUILD=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/hardware.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/hardware.o.d"  $(SILENT)  -rsi ${MP_CC_DIR}../  
	
${OBJECTDIR}/ps2.o: ps2.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ps2.o.d 
	@${RM} ${OBJECTDIR}/ps2.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  ps2.s  -o ${OBJECTDIR}/ps2.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/ps2.o.d",--defsym=__MPLAB_BUILD=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/ps2.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/ps2.o.d"  $(SILENT)  -rsi ${MP_CC_DIR}../  
	
${OBJECTDIR}/keyboard.o: keyboard.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/keyboard.o.d 
	@${RM} ${OBJECTDIR}/keyboard.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  keyboard.s  -o ${OBJECTDIR}/keyboard.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/keyboard.o.d",--defsym=__MPLAB_BUILD=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/keyboard.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/keyboard.o.d"  $(SILENT)  -rsi ${MP_CC_DIR}../  
	
${OBJECTDIR}/qwerty.o: qwerty.s  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/qwerty.o.d 
	@${RM} ${OBJECTDIR}/qwerty.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  qwerty.s  -o ${OBJECTDIR}/qwerty.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/qwerty.o.d",--defsym=__MPLAB_BUILD=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/qwerty.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/qwerty.o.d"  $(SILENT)  -rsi ${MP_CC_DIR}../  
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: assemblePreproc
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${OBJECTDIR}/TVout.o: TVout.S  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/TVout.o.d 
	@${RM} ${OBJECTDIR}/TVout.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  TVout.S  -o ${OBJECTDIR}/TVout.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -MMD -MF "${OBJECTDIR}/TVout.o.d"  -D__DEBUG -D__MPLAB_DEBUGGER_PICKIT2=1  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/TVout.o.asm.d",--defsym=__MPLAB_BUILD=1,--defsym=__ICD2RAM=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,--defsym=__MPLAB_DEBUGGER_PICKIT2=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/TVout.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/TVout.o.d" "${OBJECTDIR}/TVout.o.asm.d"  -t $(SILENT)  -rsi ${MP_CC_DIR}../  
	
${OBJECTDIR}/font.o: font.S  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/font.o.d 
	@${RM} ${OBJECTDIR}/font.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  font.S  -o ${OBJECTDIR}/font.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -MMD -MF "${OBJECTDIR}/font.o.d"  -D__DEBUG -D__MPLAB_DEBUGGER_PICKIT2=1  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/font.o.asm.d",--defsym=__MPLAB_BUILD=1,--defsym=__ICD2RAM=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,--defsym=__MPLAB_DEBUGGER_PICKIT2=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/font.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/font.o.d" "${OBJECTDIR}/font.o.asm.d"  -t $(SILENT)  -rsi ${MP_CC_DIR}../  
	
else
${OBJECTDIR}/TVout.o: TVout.S  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/TVout.o.d 
	@${RM} ${OBJECTDIR}/TVout.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  TVout.S  -o ${OBJECTDIR}/TVout.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -MMD -MF "${OBJECTDIR}/TVout.o.d"  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/TVout.o.asm.d",--defsym=__MPLAB_BUILD=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/TVout.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/TVout.o.d" "${OBJECTDIR}/TVout.o.asm.d"  -t $(SILENT)  -rsi ${MP_CC_DIR}../  
	
${OBJECTDIR}/font.o: font.S  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/font.o.d 
	@${RM} ${OBJECTDIR}/font.o 
	${MP_CC} $(MP_EXTRA_AS_PRE)  font.S  -o ${OBJECTDIR}/font.o  -c -mcpu=$(MP_PROCESSOR_OPTION)  -MMD -MF "${OBJECTDIR}/font.o.d"  -omf=elf -save-temps=obj -Wa,-MD,"${OBJECTDIR}/font.o.asm.d",--defsym=__MPLAB_BUILD=1,-g,--no-relax,--keep-locals,-al=${OBJECTDIR}/font.lst$(MP_EXTRA_AS_POST)
	@${FIXDEPS} "${OBJECTDIR}/font.o.d" "${OBJECTDIR}/font.o.asm.d"  -t $(SILENT)  -rsi ${MP_CC_DIR}../  
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: link
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
dist/${CND_CONF}/${IMAGE_TYPE}/ForthEx.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk    
	@${MKDIR} dist/${CND_CONF}/${IMAGE_TYPE} 
	${MP_CC} $(MP_EXTRA_LD_PRE)  -o dist/${CND_CONF}/${IMAGE_TYPE}/ForthEx.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}  ${OBJECTFILES_QUOTED_IF_SPACED}      -mcpu=$(MP_PROCESSOR_OPTION)        -D__DEBUG -D__MPLAB_DEBUGGER_PICKIT2=1  -omf=elf -save-temps=obj  -mreserve=data@0x800:0x822   -Wl,,--defsym=__MPLAB_BUILD=1,--defsym=__MPLAB_DEBUG=1,--defsym=__DEBUG=1,--defsym=__MPLAB_DEBUGGER_PICKIT2=1,$(MP_LINKER_FILE_OPTION),--stack=16,--check-sections,--data-init,--pack-data,--handles,--isr,--no-gc-sections,--fill-upper=0,--stackguard=16,--no-force-link,--smart-io,-Map="${DISTDIR}/${PROJECTNAME}.${IMAGE_TYPE}.map",--report-mem$(MP_EXTRA_LD_POST) 
	
else
dist/${CND_CONF}/${IMAGE_TYPE}/ForthEx.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk   
	@${MKDIR} dist/${CND_CONF}/${IMAGE_TYPE} 
	${MP_CC} $(MP_EXTRA_LD_PRE)  -o dist/${CND_CONF}/${IMAGE_TYPE}/ForthEx.X.${IMAGE_TYPE}.${DEBUGGABLE_SUFFIX}  ${OBJECTFILES_QUOTED_IF_SPACED}      -mcpu=$(MP_PROCESSOR_OPTION)        -omf=elf -save-temps=obj -Wl,,--defsym=__MPLAB_BUILD=1,$(MP_LINKER_FILE_OPTION),--stack=16,--check-sections,--data-init,--pack-data,--handles,--isr,--no-gc-sections,--fill-upper=0,--stackguard=16,--no-force-link,--smart-io,-Map="${DISTDIR}/${PROJECTNAME}.${IMAGE_TYPE}.map",--report-mem$(MP_EXTRA_LD_POST) 
	${MP_CC_DIR}/xc16-bin2hex dist/${CND_CONF}/${IMAGE_TYPE}/ForthEx.X.${IMAGE_TYPE}.${DEBUGGABLE_SUFFIX} -a  -omf=elf  
	
endif


# Subprojects
.build-subprojects:


# Subprojects
.clean-subprojects:

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r build/default
	${RM} -r dist/default

# Enable dependency checking
.dep.inc: .depcheck-impl

DEPFILES=$(shell "${PATH_TO_IDE_BIN}"mplabwildcard ${POSSIBLE_DEPFILES})
ifneq (${DEPFILES},)
include ${DEPFILES}
endif
