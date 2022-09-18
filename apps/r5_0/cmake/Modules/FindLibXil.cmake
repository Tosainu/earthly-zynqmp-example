macro(check_libxil_components name include lib)
  find_path("${name}_include" "${include}")
  find_library("${name}_lib" "${lib}")
  if(${name}_include AND ${name}_lib)
    set("LibXil_${name}_FOUND" 1)
  endif()
endmacro()

check_libxil_components(standalone xplatform_info.h libxil.a)

if(LibXil_standalone_FOUND)
  if (xilffs IN_LIST LibXil_FIND_COMPONENTS)
    check_libxil_components(xilffs ff.h libxilffs.a)
  endif()

  if(xilfpga IN_LIST LibXil_FIND_COMPONENTS)
    check_libxil_components(xilfpga xilfpga.h libxilfpga.a)
  endif()

  if(xilmailbox IN_LIST LibXil_FIND_COMPONENTS)
    check_libxil_components(xilmailbox xilmailbox.h libxilmailbox.a)
  endif()

  if(xilpm IN_LIST LibXil_FIND_COMPONENTS)
    check_libxil_components(xilpm pm_defs.h libxilpm.a)
  endif()

  if(xilsecure IN_LIST LibXil_FIND_COMPONENTS)
    check_libxil_components(xilsecure xsecure_utils.h libxilsecure.a)
  endif()

  if(xilskey IN_LIST LibXil_FIND_COMPONENTS)
    check_libxil_components(xilskey xilskey_utils.h libxilskey.a)
  endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibXil HANDLE_COMPONENTS)

if(LibXil_standalone_FOUND AND NOT TARGET LibXil::standalone)
  add_library(LibXil::standalone INTERFACE IMPORTED)
  set_target_properties(LibXil::standalone PROPERTIES
    INTERFACE_LINK_LIBRARIES "-Wl,--start-group,${standalone_lib},-lgcc,-lc,-lstdc++,--end-group"
    INTERFACE_INCLUDE_DIRECTORIES "${standalone_include}")
endif()

if(LibXil_xilffs_FOUND AND NOT TARGET LibXil::xilffs)
  add_library(LibXil::xilffs INTERFACE IMPORTED)
  set_target_properties(LibXil::xilffs PROPERTIES
    INTERFACE_LINK_LIBRARIES "LibXil::standalone;-Wl,--start-group,${xilffs_lib},${standalone_lib},-lgcc,-lc,--end-group"
    INTERFACE_INCLUDE_DIRECTORIES "${xilffs_include}")
endif()

if(LibXil_xilfpga_FOUND AND NOT TARGET LibXil::xilfpga)
  add_library(LibXil::xilfpga INTERFACE IMPORTED)
  set_target_properties(LibXil::xilfpga PROPERTIES
    INTERFACE_LINK_LIBRARIES "LibXil::standalone;-Wl,--start-group,${xilfpga_lib},${standalone_lib},-lgcc,-lc,--end-group"
    INTERFACE_INCLUDE_DIRECTORIES "${xilfpga_include}")
endif()

if(LibXil_xilmailbox_FOUND AND NOT TARGET LibXil::xilmailbox)
  add_library(LibXil::xilmailbox INTERFACE IMPORTED)
  set_target_properties(LibXil::xilmailbox PROPERTIES
    INTERFACE_LINK_LIBRARIES "LibXil::standalone;-Wl,--start-group,${xilmailbox_lib},${standalone_lib},-lgcc,-lc,--end-group"
    INTERFACE_INCLUDE_DIRECTORIES "${xilmailbox_include}")
endif()

if(LibXil_xilpm_FOUND AND NOT TARGET LibXil::xilpm)
  add_library(LibXil::xilpm INTERFACE IMPORTED)
  set_target_properties(LibXil::xilpm PROPERTIES
    INTERFACE_LINK_LIBRARIES "LibXil::standalone;-Wl,--start-group,${xilpm_lib},${standalone_lib},-lgcc,-lc,--end-group"
    INTERFACE_INCLUDE_DIRECTORIES "${xilpm_include}")
endif()

if(LibXil_xilsecure_FOUND AND NOT TARGET LibXil::xilsecure)
  add_library(LibXil::xilsecure INTERFACE IMPORTED)
  set_target_properties(LibXil::xilsecure PROPERTIES
    INTERFACE_LINK_LIBRARIES "LibXil::standalone;-Wl,--start-group,${xilsecure_lib},${standalone_lib},-lgcc,-lc,--end-group"
    INTERFACE_INCLUDE_DIRECTORIES "${xilsecure_include}")
endif()

if(LibXil_xilskey_FOUND AND NOT TARGET LibXil::xilskey)
  add_library(LibXil::xilskey INTERFACE IMPORTED)
  set_target_properties(LibXil::xilskey PROPERTIES
    INTERFACE_LINK_LIBRARIES "LibXil::standalone;-Wl,--start-group,${xilskey_lib},${standalone_lib},-lgcc,-lc,--end-group"
    INTERFACE_INCLUDE_DIRECTORIES "${xilskey_include}")
endif()
