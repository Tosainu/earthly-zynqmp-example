load mmc 0:2 ${kernel_addr_r} /boot/vmlinuz-5.15.19
load mmc 0:1 ${fdt_addr_r} /system.dtb
booti ${kernel_addr_r} - ${fdt_addr_r}
