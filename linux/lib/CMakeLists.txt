# Copy liblofty_ffi.so to the final app bundle
set(PLUGIN_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib")
set(DEST_DIR "${CMAKE_BINARY_DIR}/bundle/lib")

add_custom_command(
  TARGET ${BINARY_NAME}
  POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DEST_DIR}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
          "${PLUGIN_LIB_DIR}/liblofty_ffi.so" "${DEST_DIR}/liblofty_ffi.so")
