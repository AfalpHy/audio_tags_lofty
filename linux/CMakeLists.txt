message("${CMAKE_CURRENT_SOURCE_DIR}/lib/liblofty_ffi.so")
message("${CMAKE_INSTALL_PREFIX}/lib")

install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/lib/liblofty_ffi.so"
        DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")
