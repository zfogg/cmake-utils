# cmake-utils

Reusable CMake utilities shared by zfogg projects.

## CacheLauncher.cmake

Include `CacheLauncher.cmake` after `project()` and call:

```cmake
include(${CMAKE_CURRENT_LIST_DIR}/deps/cmake-utils/CacheLauncher.cmake)
cmake_utils_configure_cache_launcher()
```

The utility prefers `sccache` when it is on `PATH`, falls back to `ccache`,
and otherwise leaves compiler launchers unset. On Windows, sccache uses
`%LOCALAPPDATA%\\Temp\\sccache`; on Unix it uses `$XDG_CACHE_HOME/sccache`
or `$HOME/.cache/sccache`. Set `SCCACHE_DIR` in the environment to override it.

For MSVC, it configures embedded debug information (`/Z7`) so object files
remain cacheable. CMake 3.25 and newer use `CMAKE_MSVC_DEBUG_INFORMATION_FORMAT`
with policy CMP0141; older CMake versions replace `/Zi` in the debug flags.
