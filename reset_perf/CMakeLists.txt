cmake_minimum_required(VERSION 3.16)
project(spdk-reset-perf VERSION 1.0.1 DESCRIPTION "ZNS reset measurement tool in SPDK")
message(STATUS "Building using CMake version: ${CMAKE_VERSION}")
 
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
message("compiler is ${CMAKE_CXX_COMPILER_ID} and name is ${CMAKE_CXX_COMPILER}")
 
set(CMAKE_BINARY_DIR "${CMAKE_SOURCE_DIR}/bin")
set(CMAKE_LIB_DIR "${CMAKE_SOURCE_DIR}/lib")
set(EXECUTABLE_OUTPUT_PATH "${CMAKE_BINARY_DIR}")
set(LIBRARY_OUTPUT_PATH "${CMAKE_LIB_DIR}")
 
# Default to debug
if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE "Release")
endif()
# Set flags
set(BUILD_FLAGS -Wall -Wextra -Werror)
if (CMAKE_BUILD_TYPE MATCHES Debug)
   message("Building SZD in Debug mode")
   list(APPEND BUILD_FLAGS -g2 -ggdb -O1)
endif()
if (CMAKE_BUILD_TYPE MATCHES Release)
   message("Building SZD in Release mode")
   list(APPEND BUILD_FLAGS -O3)
endif()
option(FSANITIZE "Turn on fsanitize" OFF)
if (FSANITIZE)
   list(APPEND BUILD_FLAGS
       -fsanitize=address #ASAN
       -fsanitize=undefined  #UBSAN
       -fsanitize=float-divide-by-zero
       -fsanitize=float-cast-overflow 
       -fno-sanitize-recover=all
       -fno-sanitize=alignment
   )
   message("fsanitize is turned on")
endif()
 
# Sets up SPDK
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindSPDK.cmake")
 
# Add your files here
set(source_files
   "main.cpp"
)
 
# Use for each library and executable, it ensures more homogenous builds.
function(SETUP_PROJECT_STRUCTURE project_name)
   set_target_properties(${project_name} PROPERTIES LINKER_LANGUAGE CXX)
   set_property(TARGET ${project_name} PROPERTY POSITION_INDEPENDENT_CODE ON)
   target_compile_options(
       ${project_name}
       PRIVATE "${BUILD_FLAGS}"
   )
   target_link_options(
       ${project_name}
       PRIVATE "${BUILD_FLAGS}"
   )
endfunction()
 
add_executable(reset_perf "${source_files}")
target_include_directories(reset_perf PRIVATE "${SPDK_INCLUDE_DIRS}")
target_link_libraries(reset_perf PUBLIC ${SPDK_LIBRARY_DEPENDENCIES})
setup_project_structure(reset_perf)

