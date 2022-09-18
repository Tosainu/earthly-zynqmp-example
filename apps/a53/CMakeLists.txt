cmake_minimum_required(VERSION 3.16)

project(ipi-led-a53 CXX)

add_executable(ipi-led
  main.cc
)
target_compile_options(ipi-led PRIVATE "-Wall;-Wextra;-pedantic")

install(TARGETS ipi-led)
