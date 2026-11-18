# Shared compiler-cache setup for CMake projects.
# Preference: sccache, then ccache, then no launcher.

option(USE_CACHE_LAUNCHER "Use sccache or ccache when available" ON)

function(cmake_utils_configure_cache_launcher)
  if(NOT USE_CACHE_LAUNCHER)
    return()
  endif()

  find_program(CMAKE_UTILS_SCCACHE_EXECUTABLE NAMES sccache)
  find_program(CMAKE_UTILS_CCACHE_EXECUTABLE NAMES ccache)

  if(CMAKE_UTILS_SCCACHE_EXECUTABLE)
    set(_cache_tool "sccache")
    set(_cache_executable "${CMAKE_UTILS_SCCACHE_EXECUTABLE}")
  elseif(CMAKE_UTILS_CCACHE_EXECUTABLE)
    set(_cache_tool "ccache")
    set(_cache_executable "${CMAKE_UTILS_CCACHE_EXECUTABLE}")
  else()
    message(STATUS "No compiler cache launcher found (sccache/ccache)")
    return()
  endif()

  if(_cache_tool STREQUAL "sccache")
    if(WIN32)
      if(DEFINED ENV{LOCALAPPDATA} AND NOT "$ENV{LOCALAPPDATA}" STREQUAL "")
        set(_sccache_cache_dir "$ENV{LOCALAPPDATA}/Temp/sccache")
      else()
        set(_sccache_cache_dir "$ENV{TEMP}/sccache")
      endif()
    elseif(DEFINED ENV{XDG_CACHE_HOME} AND NOT "$ENV{XDG_CACHE_HOME}" STREQUAL "")
      set(_sccache_cache_dir "$ENV{XDG_CACHE_HOME}/sccache")
    else()
      set(_sccache_cache_dir "$ENV{HOME}/.cache/sccache")
    endif()
    file(MAKE_DIRECTORY "${_sccache_cache_dir}")
    set(ENV{SCCACHE_DIR} "${_sccache_cache_dir}")
    set(_cache_launcher
      "${CMAKE_COMMAND}" -E env "SCCACHE_DIR=${_sccache_cache_dir}" "CARGO_INCREMENTAL=0" "${_cache_executable}")
    message(STATUS "Using sccache: ${_cache_executable}")
    message(STATUS "sccache cache directory: ${_sccache_cache_dir}")
  else()
    set(_cache_launcher "${_cache_executable}")
    message(STATUS "Using ccache: ${_cache_executable}")
  endif()

  foreach(_language C CXX)
    if(NOT CMAKE_${_language}_COMPILER_LAUNCHER)
      set(CMAKE_${_language}_COMPILER_LAUNCHER "${_cache_launcher}" CACHE STRING
          "${_language} compiler cache launcher" FORCE)
    endif()
  endforeach()

  if(MSVC AND CMAKE_VERSION VERSION_GREATER_EQUAL "3.25")
    if(POLICY CMP0141)
      cmake_policy(SET CMP0141 NEW)
    endif()
    set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT
        "$<$<CONFIG:Debug,Dev,RelWithDebInfo>:Embedded>" CACHE STRING
        "Use embedded MSVC debug information for compiler caching" FORCE)
  elseif(MSVC)
    foreach(_config DEBUG DEV RELEASE RELWITHDEBINFO)
      string(REPLACE "/Zi" "/Z7" CMAKE_C_FLAGS_${_config} "${CMAKE_C_FLAGS_${_config}}")
      string(REPLACE "/Zi" "/Z7" CMAKE_CXX_FLAGS_${_config} "${CMAKE_CXX_FLAGS_${_config}}")
      set(CMAKE_C_FLAGS_${_config} "${CMAKE_C_FLAGS_${_config}}" CACHE STRING "" FORCE)
      set(CMAKE_CXX_FLAGS_${_config} "${CMAKE_CXX_FLAGS_${_config}}" CACHE STRING "" FORCE)
    endforeach()
  endif()

  set(CMAKE_UTILS_CACHE_TOOL "${_cache_tool}" PARENT_SCOPE)
  set(CMAKE_UTILS_CACHE_EXECUTABLE "${_cache_executable}" PARENT_SCOPE)
endfunction()

# Include this module after project() and call:
# cmake_utils_configure_cache_launcher()
