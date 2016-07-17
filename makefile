# Makefile for grinloader

# -------------------- avrdude configuration --------------------------

# Programming hardware
#
# JTAGICE3 does not work under Linux.  I have to use the AVR Dragon in
# JTAG mode.
avrdude_programmer = dragon_jtag

# Port for the AVR Dragon
avrdude_port = usb

# Part code for the xmega
avrdude_mcu = atxmega256a3bu

# Stock bootloader hex from Atmel
#
# I found a bunch of hex files linked in a avrfreaks forum:
# http://www.avrfreaks.net/forum/restore-xmega-a3bu-bootloader
# The link to the hexes is:
# http://www.atmel.com/Images/AVR1916.zip
bootloader_hex = atmel_bootloader/binary/atxmega256a3bu_104.hex

# DFU test
dfu_hex = sample_hexes/XMEGA_A3BU_XPLAINED_DEMO1.hex

# DFU device
#
# Device name needed for dfu-programmer
dfu_device = atxmega256a3bu

# ------------------------ udev configuration -------------------------
# Rules file for udev.  This sets the rules for both the Dragon and the
# stock bootloader.
udev_rules = udev/50-xmega.rules


# ----------------------- Done with configuration --------------------- 

help:
	@echo 'Makefile                                                                   '
	@echo '                                                                           '
	@echo 'Usage:                                                                     '
	@echo '   make stock_flash                                                        '
	@echo '     Flash the stock bootloader.  Make sure to connect the Dragon JTAG     '
	@echo '     output to the board                                                   '
	@echo '   make test_dfu                                                           '
	@echo '     Test the DFU by writing a hex file.  Make sure to hold down the DFU   '
	@echo '     pin, which is connected to SW0 on the XMEGA-A3BU board.  Also be sure '
	@echo '     to call udev_copy to set up the udev rules.  Finally, make sure to    '
	@echo '     disconnect the JTAG connection                                        '
	@echo '   make dragon_version                                                     '
	@echo '     Show the Dragon firmware version.  I have success for version 7.39    '
	@echo '   make udev_copy                                                          '
	@echo '     (as root) Copy the necessary udev rules                               '
	@echo '   make fuseread                                                           '
	@echo '     Read the fuse values                                                  '
	@echo '   make lockread                                                           '
	@echo '     Read the lock bits                                                    '
	@echo '   make clean                                                              '

avrdude_flags = -p $(avrdude_mcu) -c $(avrdude_programmer) -P $(avrdude_port) -e

# Flash the stock bootloader
.PHONY: stock_flash
stock_flash:
	avrdude $(avrdude_flags) -U flash:w:$(bootloader_hex)

# Show the Dragon's firmware version.  If you need to upgrade, you'll
# have to find a windows machine running AVR studio :-(
.PHONY: dragon_version
dragon_version:
	avrdude -p $(avrdude_mcu) -c $(avrdude_programmer) -P $(avrdude_port) -nv > avrdude.info 2>&1
	cat avrdude.info | grep -m 1 firmware

# Copy the necessary udev rules
.PHONY: udev_copy
udev_copy:
	cp $(udev_rules) /etc/udev/rules.d
	udevadm control --reload-rules

# Test the DFU
.PHONY: test_dfu
test_dfu:
	dfu-programmer $(dfu_device) flash $(dfu_hex)

# Read fuses
.PHONY: fuseread
fuseread:
	avrdude $(avrdude_flags) -U fuse0:r:fuse0.fuse:h \
          -U fuse1:r:fuse1.fuse:h \
          -U fuse2:r:fuse2.fuse:h \
          -U fuse4:r:fuse4.fuse:h \
          -U fuse5:r:fuse5.fuse:h
	@echo 'Fuse byte 0:'
	@cat fuse0
	@echo 'Fuse byte 1:'
	@cat fuse1
	@echo 'Fuse byte 2:'
	@cat fuse2
	@echo 'Fuse byte 4:'
	@cat fuse4
	@echo 'Fuse byte 5:'
	@cat fuse5

# Read lock bits
.PHONY: lockread
lockread:
	avrdude $(avrdude_flags) -U lock:r:lockreg:h
	@echo 'Lock register:'
	@cat lockreg

## Clean target
.PHONY: clean
clean:
	rm *.fuse
	rm *.info

## Other dependencies
-include $(shell mkdir dep 2>/dev/null) $(wildcard dep/*)

