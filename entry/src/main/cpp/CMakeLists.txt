cmake_minimum_required(VERSION 3.4.1)
project(HarmonyProxy)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -fvisibility=hidden")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -fvisibility=hidden")

set(PROXY_SOURCES
    napi/napi_init.cpp
)

add_library(entry SHARED ${PROXY_SOURCES})

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/napi
)

target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
)
