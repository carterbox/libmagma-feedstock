@echo on

:: This step is required when building from raw source archive
:: make generate --jobs %CPU_COUNT%
:: if errorlevel 1 exit /b 1

:: CUDAARCHS set by nvcc compiler package

md build
cd build
if errorlevel 1 exit /b 1

:: Must add --use-local-env to CUDAFLAGS otherwise NVCC autoconfigs the host
:: compiler to cl.exe instead of the full path.
set CUDAFLAGS=--use-local-env

:: Compress SASS and PTX in the binary to reduce disk usage
@REM set CUDAFLAGS=%CUDAFLAGS% -Xfatbin -compress-all

@REM if "%cuda_compiler_version:~0,3%"=="13." (
@REM   set CUDAFLAGS=%CUDAFLAGS% -Xfatbin -compress-mode=size
@REM )

:: Force 64-bit PE32+ format (not 32-bit PE32) to avoid the 2GB image size limit
:: PE32+ has much higher limits suitable for large libraries like MAGMA
:: /MACHINE:X64 explicitly sets 64-bit linking
:: /LARGEADDRESSAWARE:NO is default for 32-bit
set "LDFLAGS=%LDFLAGS% /MACHINE:X64 /INCREMENTAL:NO /OPT:ICF"

:: Must set CMAKE_CXX_STANDARD=17 because CCCL from CUDA 13 has dropped C++14
cmake %SRC_DIR% ^
  -G "Ninja" ^
  -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS:BOOL=ON ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
  -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
  -DMAGMA_ENABLE_CUDA:BOOL=ON ^
  -DUSE_FORTRAN:BOOL=OFF ^
  -DCMAKE_CUDA_SEPARABLE_COMPILATION:BOOL=OFF ^
  -DCMAKE_CXX_STANDARD=17 ^
  %CMAKE_ARGS%
if errorlevel 1 exit /b 1

:: Explicitly name build targets to avoid building tests
cmake --build . ^
    --config Release ^
    --parallel %CPU_COUNT% ^
    --target magma magma_sparse ^
    --verbose
if errorlevel 1 exit /b 1

cmake --install .
if errorlevel 1 exit /b 1
