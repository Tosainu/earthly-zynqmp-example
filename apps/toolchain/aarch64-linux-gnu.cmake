set(CMAKE_SYSTEM_NAME "Linux")
set(CMAKE_SYSTEM_PROCESSOR "aarch64")

set(CMAKE_C_COMPILER "aarch64-linux-gnu-gcc")
set(CMAKE_CXX_COMPILER "aarch64-linux-gnu-g++")

set(CMAKE_C_FLAGS_INIT "-march=armv8-a+crypto+crc -mcpu=cortex-a53")
set(CMAKE_CXX_FLAGS_INIT "-march=armv8-a+crypto+crc -mcpu=cortex-a53")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-march=armv8-a+crypto+crc -mcpu=cortex-a53")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
