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
set CUDAFLAGS=%CUDAFLAGS% -Xfatbin -compress-all

:: Ship some PTX instead of SASS to save space. These archs are shipped as SASS in the CUDA
:: 13.0 build, so they are somewhat redundant. SASS before 75 is not redundant because it is
:: dropped in CUDA 13.0. Users can upgrade to CTK 13.0 to avoid JIT.
if "%cuda_compiler_version:~0,3%"=="12." (
  : 80
  set "CUDAARCHS=%CUDAARCHS:86-real=86-virtual%"
  set "CUDAARCHS=%CUDAARCHS:89-real=89-virtual%"
  : 90
  : 100
  set "CUDAARCHS=%CUDAARCHS:103f-real=103f-virtual%"
  : 120
  set "CUDAARCHS=%CUDAARCHS:121f-real=121f-virtual%"
)

if "%cuda_compiler_version:~0,3%"=="13." (
  set CUDAFLAGS=%CUDAFLAGS% -Xfatbin -compress-mode=size
)

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
