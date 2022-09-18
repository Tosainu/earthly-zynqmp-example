cmake_minimum_required(VERSION 3.16)

project(ipi-led-r5 CXX)

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules/" "${CMAKE_MODULE_PATH}")

find_package(LibXil
  COMPONENTS standalone
  REQUIRED
)

add_executable(ipi-led
  main.cc
)
target_link_libraries(ipi-led PRIVATE
  LibXil::standalone
)
target_compile_options(ipi-led PRIVATE "-Wall;-Wextra;-pedantic")
target_link_options(ipi-led PRIVATE "-Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/lscript.ld")
set_target_properties(ipi-led PROPERTIES
  CXX_EXTENSIONS OFF
  CXX_STANDARD 20
  CXX_STANDARD_REQUIRED ON
  LINK_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/lscript.ld"
  SUFFIX ".elf"
)

install(TARGETS ipi-led)
