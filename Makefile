
# ============================================================
# PULS - STM32C031C6Tx
# Linux / GNU Arm Embedded Toolchain
# CMSIS, direct register access, no HAL
# ============================================================

PROJECT   := PULS
BUILD_DIR := build

# Toolchain
CC      := arm-none-eabi-gcc
OBJCOPY := arm-none-eabi-objcopy
SIZE    := arm-none-eabi-size
GDB     := arm-none-eabi-gdb

# Target CPU
CPU := -mcpu=cortex-m0plus -mthumb

# Device definition
DEFINES := -DSTM32C031xx

# Include paths
INCLUDES := \
	-IInc \
	-ICore/Inc \
	-IDrivers/CMSIS/Include \
	-IDrivers/CMSIS/Device/ST/STM32C0xx/Include

# C compiler flags
CFLAGS := $(CPU) \
	$(DEFINES) \
	$(INCLUDES) \
	-std=gnu11 \
	-Og \
	-Wall -Wextra \
	-ffunction-sections \
	-fdata-sections \
	-fno-common \
	-MMD -MP

# Assembler flags
ASFLAGS := $(CPU) \
	$(DEFINES) \
	$(INCLUDES) \
	-MMD -MP

# Linker script
LDSCRIPT := STM32C031C6TX_FLASH.ld

# C library:
# Default: newlib + stubs for unsupported system calls
SPECS ?= --specs=nano.specs

LDFLAGS := $(CPU) \
	-T$(LDSCRIPT) \
	$(SPECS) \
	-Wl,--gc-sections \
	-Wl,-Map=$(BUILD_DIR)/$(PROJECT).map \
	-Wl,--print-memory-usage

# Source files
C_SOURCES := \
	Src/main.c \
	Src/syscalls.c \
	Src/sysmem.c \
	Drivers/CMSIS/Device/ST/STM32C0xx/Source/Templates/system_stm32c0xx.c

ASM_SOURCES := \
	Startup/startup_stm32c031c6tx.s

# Object files
OBJECTS := \
	$(patsubst %.c,$(BUILD_DIR)/%.o,$(C_SOURCES)) \
	$(patsubst %.s,$(BUILD_DIR)/%.o,$(ASM_SOURCES))

DEPS := $(OBJECTS:.o=.d)

# ============================================================
# Targets
# ============================================================

.PHONY: all clean flash size info

all: $(BUILD_DIR)/$(PROJECT).elf \
     $(BUILD_DIR)/$(PROJECT).hex \
     $(BUILD_DIR)/$(PROJECT).bin

# ELF: compile and link
$(BUILD_DIR)/$(PROJECT).elf: $(OBJECTS) 
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@
	$(SIZE) $@

# Intel HEX
$(BUILD_DIR)/$(PROJECT).hex: $(BUILD_DIR)/$(PROJECT).elf
	$(OBJCOPY) -O ihex $< $@

# Binary image
$(BUILD_DIR)/$(PROJECT).bin: $(BUILD_DIR)/$(PROJECT).elf
	$(OBJCOPY) -O binary $< $@

# Compile C sources
$(BUILD_DIR)/%.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# Assemble startup
$(BUILD_DIR)/%.o: %.s
	mkdir -p $(dir $@)
	$(CC) $(ASFLAGS) -c $< -o $@

# Flash using ST-Link
flash: $(BUILD_DIR)/$(PROJECT).bin
	st-flash write $< 0x08000000

# Show memory usage
size: $(BUILD_DIR)/$(PROJECT).elf
	$(SIZE) $<

# Show toolchain versions
info:
	$(CC) --version
	$(CC) -print-sysroot
	$(CC) -print-file-name=libc.a
	$(CC) -print-file-name=nosys.specs

# Remove generated files
clean:
	rm -rf $(BUILD_DIR)

# Include dependency files
-include $(DEPS)
