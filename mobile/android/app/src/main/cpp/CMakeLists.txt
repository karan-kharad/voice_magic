cmake_minimum_required(VERSION 3.22.1)
project("voicechanger_dsp")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(voicechanger_dsp SHARED
    AudioEngine.cpp
)

target_include_directories(voicechanger_dsp PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

find_library(log-lib log)
find_library(android-lib android)
find_library(aaudio-lib aaudio)

target_link_libraries(voicechanger_dsp
    ${log-lib}
    ${android-lib}
    ${aaudio-lib}
)
