set xsa_file [lindex $argv 0]

hsi open_hw_design $xsa_file

set bit_file [lindex [hsi get_hw_files -filter {TYPE==bit}] 0]
file link -symbolic system.bit $bit_file

hsi set_repo_path embeddedsw

hsi create_sw_design fsbl -proc psu_cortexa53_0 -os standalone
hsi set_property CONFIG.stdin  psu_uart_1 [hsi get_os]
hsi set_property CONFIG.stdout psu_uart_1 [hsi get_os]
hsi add_library xilffs
hsi add_library xilpm
hsi add_library xilsecure
hsi generate_app -app zynqmp_fsbl -dir fsbl
hsi close_sw_design [hsi current_sw_design]

hsi create_sw_design pmufw -proc psu_pmu_0 -os standalone
hsi set_property CONFIG.stdin  psu_uart_1 [hsi get_os]
hsi set_property CONFIG.stdout psu_uart_1 [hsi get_os]
hsi add_library xilfpga
hsi add_library xilsecure
hsi add_library xilskey
hsi generate_app -app zynqmp_pmufw -dir pmufw
hsi close_sw_design [hsi current_sw_design]

hsi create_sw_design bsp_psu_cortexr5_0 -proc psu_cortexr5_0 -os standalone
hsi set_property CONFIG.stdin  psu_uart_1 [hsi get_os]
hsi set_property CONFIG.stdout psu_uart_1 [hsi get_os]
# hsi add_library xilffs
# hsi add_library xilfpga
# hsi add_library xilmailbox
# hsi add_library xilpm
# hsi add_library xilsecure
# hsi add_library xilskey
hsi generate_bsp -dir bsp_psu_cortexr5_0
hsi close_sw_design [hsi current_sw_design]

hsi set_repo_path device-tree-xlnx

hsi create_sw_design device-tree -proc psu_cortexa53_0 -os device_tree
hsi set_property CONFIG.console_device psu_uart_1 [hsi get_os]
hsi generate_target -dir device-tree
