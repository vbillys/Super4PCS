
# EXTERNALS
# have ExternalProject available
include(ExternalProject)
message("[Super4PCS] Use Chealpix")

ExternalProject_Add(
        cfitsio
        # where the source will live
        SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/cfitsio"
        INSTALL_DIR "${INSTALL_DIR}/"

        CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>

        # override default behaviours
        UPDATE_COMMAND ""
)

add_subdirectory(${PROJECT_SOURCE_DIR}/3rdparty/chealpix)
add_definitions(-DSUPER4PCS_USE_CHEALPIX)
include_directories(${Chealpix_INCLUDE_DIR})
