cmake_minimum_required (VERSION 2.6)
project (Super4PCS)

################################################################################
## User options
################################################################################
# Set option to enable timing recording
OPTION (SUPER4PCS_COMPILE_TESTS "Enable testing" TRUE)
OPTION (IO_USE_OPENCV "Use OpenCV for texture loading" TRUE)
OPTION (ENABLE_TIMING "Enable computation time recording" FALSE)
OPTION (SUPER4PCS_USE_CHEALPIX "Use Chealpix for orientation filtering (deprecated)" FALSE)
OPTION (DL_DATASETS "Download demo datasets and associated run scripts" FALSE)

################################################################################
## DO NOT EDIT AFTER THIS LINE
##
## Variables configuration
################################################################################
set (Super4PCS_VERSION_MAJOR 1)
set (Super4PCS_VERSION_MINOR 1)

set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
set(SRC_DIR ${PROJECT_SOURCE_DIR}/src/)
set(ASSETS_DIR ${PROJECT_SOURCE_DIR}/assets)
set(SCRIPTS_DIR ${PROJECT_SOURCE_DIR}/scripts)
set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

if(NOT INSTALL_DIR)
  set(INSTALL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Super4PCS-${Super4PCS_VERSION_MAJOR}.${Super4PCS_VERSION_MINOR})
endif(NOT INSTALL_DIR)

################################################################################
## GUARDS
################################################################################

# guard against in-source builds (source: Eigen)
if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
  message(FATAL_ERROR "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there. You may need to remove CMakeCache.txt. ")
endif()

# guard against bad build-type strings (source: Eigen)
if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release")
endif()
string(TOLOWER "${CMAKE_BUILD_TYPE}" cmake_build_type_tolower)
if(    NOT cmake_build_type_tolower STREQUAL "debug"
   AND NOT cmake_build_type_tolower STREQUAL "release"
   AND NOT cmake_build_type_tolower STREQUAL "relwithdebinfo")
  message(FATAL_ERROR "Unknown build type \"${CMAKE_BUILD_TYPE}\". Allowed values are Debug, Release, RelWithDebInfo (case-insensitive).")
endif()

################################################################################
## Compiler configuration
################################################################################
include(cmake/ConfigureCompiler.cmake)

################################################################################
## Apply user-defined configuration
################################################################################
if (ENABLE_TIMING)
    ADD_DEFINITIONS( -DTEST_GLOBAL_TIMINGS )
    message (STATUS "OPT: Enable timing recording")
endif (ENABLE_TIMING)

if (DL_DATASETS)
    add_custom_target(dl-datasets)
    include(ExternalProject)

    ExternalProject_Add(dl-dataset-demo1
        SOURCE_DIR ${ASSETS_DIR}/demo1
        URL https://www.irit.fr/~Nicolas.Mellado/dl/datasets/point-clouds/Super4PCS-dataset-demo1.zip
        URL_MD5 ad1e172902b41a3f17e9b4901adf3ba5
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_DIR "${INSTALL_DIR}/"
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        INSTALL_COMMAND ""
    )
    add_dependencies(dl-datasets dl-dataset-demo1)
endif (DL_DATASETS)

################################################################################
## Dependencies
################################################################################

if(SUPER4PCS_USE_CHEALPIX)
    include(cmake/ConfigureChealpix.cmake)
endif(SUPER4PCS_USE_CHEALPIX)

## Eigen: automatic configuration:
##  1. if EIGEN3_INCLUDE_DIR is set, use it directly
##  2. if any, and version >= 3.3.x, use system version
##  3. otherwise, download (if required) and use submodule
if( NOT EIGEN3_INCLUDE_DIR )
    find_package(Eigen3 QUIET)
    if( (NOT Eigen3_FOUND) OR EIGEN_VERSION_NUMBER VERSION_LESS 3.3 )

        set(EIGEN3_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/3rdparty/Eigen")

        if( NOT EXISTS ${EIGEN3_INCLUDE_DIR}/signature_of_eigen3_matrix_library )
            execute_process(COMMAND git submodule update --init -- ${EIGEN3_INCLUDE_DIR}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
        endif( NOT EXISTS ${EIGEN3_INCLUDE_DIR}/signature_of_eigen3_matrix_library )
    endif()
endif( NOT EIGEN3_INCLUDE_DIR )
include_directories(${EIGEN3_INCLUDE_DIR})
message(STATUS "-- Eigen3 root path: ${EIGEN3_INCLUDE_DIR}")

################################################################################
## Tests, assets and scripts
################################################################################

if(SUPER4PCS_COMPILE_TESTS)
        include(cmake/ConfigureTesting.cmake)
        add_subdirectory(tests EXCLUDE_FROM_ALL)
endif(SUPER4PCS_COMPILE_TESTS)

include(cmake/AssetsAndScripts.cmake)

################################################################################
## Super4PCS algo
################################################################################

include_directories(${SRC_DIR})
set(Super4PCS_SRC
    ${SRC_DIR}/super4pcs/algorithms/match4pcsBase.cc
    ${SRC_DIR}/super4pcs/algorithms/4pcs.cc
    ${SRC_DIR}/super4pcs/algorithms/super4pcs.cc
)
set(Super4PCS_INCLUDE
    ${SRC_DIR}/super4pcs/sampling.h
    ${SRC_DIR}/super4pcs/shared4pcs.h
    ${SRC_DIR}/super4pcs/pairExtraction.h
    ${SRC_DIR}/super4pcs/algorithms/match4pcsBase.h
    ${SRC_DIR}/super4pcs/algorithms/4pcs.h
    ${SRC_DIR}/super4pcs/algorithms/super4pcs.h
    ${SRC_DIR}/super4pcs/pairCreationFunctor.h
)

add_subdirectory(${SRC_DIR}/super4pcs/io)
add_subdirectory(${SRC_DIR}/super4pcs/utils)
add_subdirectory(${SRC_DIR}/super4pcs/accelerators)

add_library(super4pcs_algo ${Super4PCS_SRC} ${Super4PCS_INCLUDE})
if(SUPER4PCS_USE_CHEALPIX)
    target_link_libraries(super4pcs_algo ${Chealpix_LIBS} )
endif(SUPER4PCS_USE_CHEALPIX)

# add the executable
add_executable(${PROJECT_NAME} ${SRC_DIR}/super4pcs/super4pcs_test.cc)

target_link_libraries(super4pcs_algo super4pcs_io super4pcs_accel)
target_link_libraries(${PROJECT_NAME} super4pcs_algo super4pcs_utils)

install( TARGETS super4pcs_algo ${PROJECT_NAME}
    RUNTIME DESTINATION ${INSTALL_DIR}/bin
    LIBRARY DESTINATION ${INSTALL_DIR}/lib
    ARCHIVE DESTINATION ${INSTALL_DIR}/lib )

