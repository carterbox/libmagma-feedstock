set -exv

# This step is required when building from raw source archive
# make generate --jobs ${CPU_COUNT}

# CUDAARCHS set by nvcc compiler package
export CUDAARCHS="89"

# Conda-forge nvcc compiler flags environment variable doesn't match CMake environment variable
# Redirect it so that the flags are added to nvcc calls
export CUDAFLAGS="${CUDAFLAGS} ${CUDA_CFLAGS}"

# Compress SASS and PTX in the binary to reduce disk usage
# export CUDAFLAGS="${CUDAFLAGS} -Xfatbin -compress-all"

mkdir build
cd build

# Must set CMAKE_CXX_STANDARD=17 because CCCL from CUDA 13 has dropped C++14
cmake $SRC_DIR \
  -G "Ninja" \
  -DBUILD_SHARED_LIBS:BOOL=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DMAGMA_ENABLE_CUDA:BOOL=ON \
  -DUSE_FORTRAN:BOOL=OFF \
  -DCMAKE_CUDA_SEPARABLE_COMPILATION:BOOL=OFF \
  -DCMAKE_CXX_STANDARD=17 \
  ${CMAKE_ARGS}

# Explicitly name build targets to avoid building tests
cmake --build . \
    --config Release \
    --parallel ${CPU_COUNT} \
    --verbose

cmake --install .  --strip

# Copy tests to prefix
mkdir -p $PREFIX/bin
strip --strip-unneeded $SRC_DIR/build/testing/*
cp -r $SRC_DIR/build/testing/* $PREFIX/bin/
cp -r $SRC_DIR/testing/run*.py $PREFIX/bin/
mkdir -p $PREFIX/lib
cp -r $SRC_DIR/build/lib/*test*.so $PREFIX/lib/
