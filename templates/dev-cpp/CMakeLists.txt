cmake_minimum_required(VERSION 3.20)
project(cpp-project)

if (NOT CMAKE_BUILD_TYPE)
    message(WARNING "No build type provided. Defaulting to 'Debug'")
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Options: Debug, Release, RelWithDebInfo, MinSizeRel" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release RelWithDebInfo MinSizeRel)
endif()

include(cmake/get_cpm.cmake)

CPMAddPackage(
    URI "gh:gabime/spdlog#v1.15.3"
    OPTIONS
        "SPDLOG_NO_EXCEPTIONS ON"
)

add_executable(${PROJECT_NAME}
    src/main.cc
    src/utils.cc
)

set_target_properties(${PROJECT_NAME} PROPERTIES
    CXX_STANDARD 23
    CXX_STANDARD_REQUIRED ON
#   OUTPUT_NAME "${PROJECT_NAME}"
#   LIBRARY_OUTPUT_NAME "${PROJECT_NAME}"
#   PREFIX ""
#   SUFFIX ".bin"
#   RUNTIME_OUTPUT_DIRECTORY ""
#   LIBRARY_OUTPUT_DIRECTORY ""
)

target_link_libraries(${PROJECT_NAME} PRIVATE #-static
    spdlog::spdlog
)

if(MINGW AND CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES)
    list(GET CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES -1 mingw_w64_include_dir)
    target_compile_options(${PROJECT_NAME} PRIVATE "SHELL:-isystem ${mingw_w64_include_dir}")
endif()

target_compile_options(${PROJECT_NAME}
    PRIVATE
        $<$<OR:$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:GNU>,$<C_COMPILER_ID:Clang>,$<C_COMPILER_ID:GNU>>:
            -Wall -Wextra -Wpedantic -Werror -Wsign-conversion
            -fno-exceptions
            -fno-rtti
            -ffile-prefix-map=${CMAKE_CURRENT_SOURCE_DIR}/=
        >
        $<$<OR:$<CXX_COMPILER_ID:MSVC>,$<C_COMPILER_ID:MSVC>>:
            /W4 /WX
        >
)

target_compile_definitions(${PROJECT_NAME} PRIVATE
    $<$<BOOL:${EXTERNAL_NAME}>:EXTERNAL_NAME="${EXTERNAL_NAME}">
    $<$<CONFIG:Debug>:IS_DEBUG=1>
    $<IF:$<CONFIG:Debug>,SPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_DEBUG,SPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_ERROR>
)
