
# Override to use different location for SPDK.
set(SPDK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../submodules/spdk")
message("looking for SPDK in ${SPDK_DIR}")
 
find_package(PkgConfig REQUIRED)
if(NOT PKG_CONFIG_FOUND)
   message(FATAL_ERROR "pkg-config command not found!" )
endif()
 
# Needed to ensure that PKG_CONFIG also looks at our SPDK installation.
set(ENV{PKG_CONFIG_PATH} "$ENV{PKG_CONFIG_PATH}:${SPDK_DIR}/build/lib/pkgconfig/")
message("Looking for SPDK packages...")
pkg_search_module(SPDK REQUIRED IMPORTED_TARGET spdk_nvme)
pkg_search_module(DPDK REQUIRED IMPORTED_TARGET spdk_env_dpdk)
pkg_search_module(SYS REQUIRED IMPORTED_TARGET spdk_syslibs)
 
set(SPDK_INCLUDE_DIRS "${SPDK_INCLUDE_DIRS}")
 
# TODO: Solve this once there is one sane CMake for SPDK somewhere
# The following is what is done in the wiki of SPDK, but does not work as of 2022-11-09.
# It will use a shared lib, not what we want! It uses wrong files in both sections and wrong types (static vs linked).
# set(SPDK_AND_DPDK_LIBRARIES "${SPDK_LINK_LIBRARIES}" "${DPDK_LINK_LIBRARIES}")
# list(REMOVE_DUPLICATES SPDK_AND_DPDK_LIBRARIES)
# set(SPDK_LIBRARY_DEPENDENCIES
#     -Wl,--whole-archive
#     "${SPDK_AND_DPDK_LIBRARIES}"
#     -Wl,--no-whole-archive
#     "${SYS_STATIC_LIBRARIES}"
# )
 
# Fix libs.
#   issue 1: many libs erroneously point to .so, but must be .a
#   issue 2: duplicates in DPDK and SPDK libs
#   issue 3: spdk_env_dpdk needs to be whole-archive, unlike the other DPDK deps...
#   issue 4: there is no SYS_STATIC_LINK_LIBRARIES, so we need a quick and dirty solution for now to get isa-l
list(TRANSFORM SPDK_LINK_LIBRARIES REPLACE "[.]so$" ".a")
list(TRANSFORM DPDK_LINK_LIBRARIES REPLACE "[.]so$" ".a")
set(SPDK_ENV_DPDK_VAR "")
foreach(DPDK_LIB ${DPDK_LINK_LIBRARIES})
   if(DPDK_LIB MATCHES ".*spdk_env_dpdk.*")
       set(SPDK_ENV_DPDK_VAR "${DPDK_LIB}")
   endif()
endforeach()
list(APPEND SPDK_LINK_LIBRARIES "${SPDK_ENV_DPDK_VAR}")
list(REMOVE_ITEM DPDK_LINK_LIBRARIES "${SPDK_ENV_DPDK_VAR}" ${SPDK_LINK_LIBRARIES})
list(TRANSFORM SYS_STATIC_LIBRARIES REPLACE "isal" "${SYS_STATIC_LIBRARY_DIRS}/libisal.a")

message("${SPDK_DIR}/build/lib/spdk_log.a")

set(SPDK_LIBRARY_DEPENDENCIES
    -Wl,--whole-archive
    ${SPDK_DIR}/build/lib/libspdk_log.a ${SPDK_DIR}/build/lib/libspdk_env_dpdk.a ${SPDK_DIR}/build/lib/libspdk_nvme.a
    ${SPDK_DIR}/build/lib/libspdk_util.a ${SPDK_DIR}/build/lib/libspdk_sock.a ${SPDK_DIR}/build/lib/libspdk_json.a
    ${SPDK_DIR}/build/lib/libspdk_vfio_user.a ${SPDK_DIR}/build/lib/libspdk_rpc.a ${SPDK_DIR}/build/lib/libspdk_jsonrpc.a 
    ${SPDK_DIR}/build/lib/libspdk_trace.a
    -Wl,--no-whole-archive
    ${SPDK_DIR}/dpdk/build/lib/librte_eal.a ${SPDK_DIR}/dpdk/build/lib/librte_mempool.a  ${SPDK_DIR}/dpdk/build/lib/librte_telemetry.a
    ${SPDK_DIR}/dpdk/build/lib/librte_ring.a  ${SPDK_DIR}/dpdk/build/lib/librte_kvargs.a ${SPDK_DIR}/dpdk/build/lib/librte_bus_pci.a
    ${SPDK_DIR}/dpdk/build/lib/librte_pci.a  ${SPDK_DIR}/dpdk/build/lib/librte_vhost.a  ${SPDK_DIR}/dpdk/build/lib/librte_power.a
    isal.a uuid numa dl rt
)

#set(SPDK_LIBRARY_DEPENDENCIES
#   -Wl,--whole-archive
#   "${SPDK_LINK_LIBRARIES}"
#   -Wl,--no-whole-archive
#   "${DPDK_LINK_LIBRARIES}"    "${SYS_STATIC_LIBRARIES}"
#    /usr/local/lib/librte_log.a /usr/local/lib/librte_cryptodev.a
#)

message("${SPDK_LIBRARY_DEPENDENCIES}")