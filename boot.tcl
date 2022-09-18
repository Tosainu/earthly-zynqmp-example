set build_dir "."
set hw_server_url ""

if { $::argc > 0 } {
  for { set i 0 } { $i < $::argc } { incr i } {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--build_dir" { incr i; set build_dir [lindex $::argv $i] }
      "--url"       { incr i; set hw_server_url [lindex $::argv $i] }
      default {
        if { [regexp {^-} $option] } {
          puts "\[ERROR\]: Unknown option '$option'"
          return 1
        }
      }
    }
  }
}

if { [string length $hw_server_url] } {
  puts "\[+\] connect remote hw_server @ $hw_server_url"
  connect -url $hw_server_url -symbols
} else {
  connect
}

puts "\[+\] reset system"
targets -set -filter {name == "PSU"}
rst -system

puts "\[+\] PL: system.bit"
targets -set -filter {name == "PL"}
fpga -f "$build_dir/system.bit"

puts "\[+\] PMU: pmufw.elf"
targets -set -filter {name == "PSU"}
# CSU.jtag_sec register, set [8:0] bits to disabole JTAG security gates
mwr 0xffca0038 0x1ff
target -set -filter {name == "MicroBlaze PMU"}
dow "$build_dir/pmufw.elf"
con

puts "\[+\] A53 #0: fsbl.elf"
targets -set -filter {name =~ "*A53*#0"}
rst -processor -clear-registers
dow "$build_dir/fsbl.elf"
set fsbl_bp [bpadd -addr &XFsbl_Loop]
con -block -timeout 30
bpremove $fsbl_bp

puts "\[+\] A53 #0: u-boot.elf, bl31.elf"
targets -set -filter {name =~ "*A53*#0"}
dow "$build_dir/u-boot.elf"
dow "$build_dir/bl31.elf"
dow -data "$build_dir/system.dtb" 0x100000
dow -data "$build_dir/boot.scr" 0x20000000
con

puts "\[+\] R5 #0: ipi-led.elf"
targets -set -filter {name =~ "*R5*#0"}
rst -processor -clear-registers
dow -clear -skip-tcm-clear "$build_dir/ipi-led.elf"
con
