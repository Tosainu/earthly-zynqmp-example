set(CMAKE_SYSTEM_NAME "Generic")
set(CMAKE_SYSTEM_PROCESSOR "arm")

set(CMAKE_C_COMPILER "armr5-none-eabi-gcc")
set(CMAKE_CXX_COMPILER "armr5-none-eabi-g++")

set(CMAKE_C_FLAGS_INIT "-mfloat-abi=hard -mfpu=vfpv3-d16 -mcpu=cortex-r5 -DARMR5")
set(CMAKE_CXX_FLAGS_INIT "-mfloat-abi=hard -mfpu=vfpv3-d16 -mcpu=cortex-r5 -DARMR5")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-mfloat-abi=hard -mfpu=vfpv3-d16 -mcpu=cortex-r5")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
