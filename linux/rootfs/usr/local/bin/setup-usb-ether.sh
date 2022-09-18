#!/bin/sh -e

usb_gadget=/sys/kernel/config/usb_gadget
if [ ! -d "$usb_gadget" ]; then
  exit 1
fi

dev="$usb_gadget/g"
mkdir -p "$dev"

echo 0x1d6b > "$dev/idVendor"   # Linux Foundation
echo 0x0104 > "$dev/idProduct"  # Multifunction Composite Gadget
echo 0x0100 > "$dev/bcdDevice"  # v1.0.0
echo 0x0200 > "$dev/bcdUSB"     # USB 2.0

echo 0xEF > "$dev/bDeviceClass"
echo 0x02 > "$dev/bDeviceSubClass"
echo 0x01 > "$dev/bDeviceProtocol"

mkdir -p "$dev/strings/0x409"
echo "0123456789" > "$dev/strings/0x409/serialnumber"
echo "Avnet" > "$dev/strings/0x409/manufacturer"
echo "Ultra96-V2 Gadget" > "$dev/strings/0x409/product"

#
# config 1: CDC
#
mkdir -p "$dev/functions/ecm.usb0"

mkdir -p "$dev/configs/c.1"
echo 250 > "$dev/configs/c.1/MaxPower"
ln -s "$dev/functions/ecm.usb0" "$dev/configs/c.1"

#
# config 2: RNDIS
#
mkdir -p "$dev/functions/rndis.usb0"

echo 1 > "$dev/os_desc/use"
echo 0xcd > "$dev/os_desc/b_vendor_code"  # Microsoft
echo MSFT100 > "$dev/os_desc/qw_sign"

echo RNDIS > "$dev/functions/rndis.usb0/os_desc/interface.rndis/compatible_id"
echo 5162001 > "$dev/functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id"  # use Windows RNDIS 6.0 Driver

mkdir -p "$dev/configs/c.2"
echo 250 > "$dev/configs/c.2/MaxPower"
ln -s "$dev/functions/rndis.usb0" "$dev/configs/c.2"
ln -s "$dev/configs/c.2" "$dev/os_desc"

echo fe200000.usb > "$dev/UDC"
