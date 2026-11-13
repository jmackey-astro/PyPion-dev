#!/bin/bash
#
# Download, compile and install the Silo library (https://github.com/LLNL/Silo)
# with its python module (Silo.so), which PyPion uses to read PION snapshots.
#
# Authors: Jonathan Mackey, Harpreet Dhanoa, Sam Green
#
# - 2012-2020: ongoing development to add options for new machines.
# - 2023.10.03 JM: updates for new MacOS
# - 2026.11.13 JM: Silo 4.12.x, which is built with CMake (no more
#   ./configure script).  Based on extra_libraries/install_silo.sh in PION.
#   Registers Silo with the active python virtual environment.
#
# Usage (run it in an empty directory; it downloads and builds Silo there):
#   source ~/pypion-venv/bin/activate      (recommended, see README.md)
#   mkdir -p ~/.cache/silo-build && cd ~/.cache/silo-build
#   bash /path/to/PyPion/src/silo/install_silo.sh
#
# Optional environment variables to override defaults:
#   SILO_VER=4.12.1                 Silo version to download
#   SILO_PREFIX=$HOME/.local/silo   installation directory
#   NCORES=4                        number of parallel compile jobs
#   SILO_HDF5_DIR=/path/to/hdf5     build Silo with the HDF5 driver (not
#                                   needed for PION, which uses PDB files)
#
# Requirements:
#   Debian/Ubuntu: sudo apt install build-essential cmake wget python3-dev python3-venv
#   MacOS (homebrew): brew install python3 cmake wget
#
# The python module is compiled for the python3 that is first in your PATH
# (i.e. the one in the active virtual environment), and it only works with
# that python version.  If you upgrade python, run this script again.
#

VER=${SILO_VER:-4.12.1}
PREFIX=${SILO_PREFIX:-$HOME/.local/silo}
NCORES=${NCORES:-4}
export CC=${CC:-gcc}
export CXX=${CXX:-g++}

if [ "$(uname -s)" == "Darwin" ]; then
  echo "***** Compiling on MacOS"
  export CC=clang
  export CXX=clang++
fi

PYTHON=$(command -v python3)
if [ -z "$PYTHON" ]; then
  echo "ERROR: python3 not found."
  exit 1
fi
echo "Using python: ${PYTHON} ($($PYTHON --version 2>&1))"

# The python module needs the Python development headers (Python.h).
PY_H=$($PYTHON -c "import sysconfig,os; print(os.path.isfile(os.path.join(sysconfig.get_paths()['include'],'Python.h')))" 2>/dev/null)
if [ "$PY_H" != "True" ]; then
  echo "ERROR: Python development headers (Python.h) not found for ${PYTHON}."
  echo "  Debian/Ubuntu: sudo apt install python3-dev"
  exit 1
fi

if ! command -v cmake >/dev/null 2>&1; then
  echo "ERROR: cmake not found (Silo >= 4.12 needs CMake >= 3.19)."
  exit 1
fi
echo "Using $(cmake --version | head -1)"

echo "********************************"
echo "*** INSTALLING SILO LIBRARY ****"
echo "*** version ${VER}"
echo "*** prefix  ${PREFIX}"
echo "********************************"

REMOTE_URL=https://github.com/LLNL/Silo/releases/download/${VER}/Silo-${VER}.tar.xz
FILE=Silo-${VER}.tar.xz
SRC_DIR=Silo-${VER}
BUILD_DIR=build-silo-${VER}

if [ -s $FILE ]; then
  echo "*** File exists, no need to download ***"
else
  echo "*** DOWNLOADING SILO LIBRARY ***"
  rm -f $FILE
  if command -v wget >/dev/null 2>&1; then
    wget $REMOTE_URL -O $FILE
  fi
  if [ ! -s $FILE ]; then
    rm -f $FILE
    curl --location --fail $REMOTE_URL -o $FILE
  fi
  if [ ! -s $FILE ]; then
    rm -f $FILE
    echo "Download of Silo Library from ${REMOTE_URL} failed... quitting"
    exit 1
  fi
fi

echo "*** EXTRACTING SILO LIBRARY ***"
rm -rf $SRC_DIR $BUILD_DIR
tar -xJf $FILE || exit 1
mkdir -p $BUILD_DIR $PREFIX

CMAKE_EXTRA=""
SILO_HDF5=OFF
if [ ! -z "$SILO_HDF5_DIR" ]; then
  SILO_HDF5=ON
  CMAKE_EXTRA="-DSILO_HDF5_DIR=${SILO_HDF5_DIR}"
fi

echo "*** RUNNING CMAKE ***"
cmake -S $SRC_DIR -B $BUILD_DIR \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_C_COMPILER=${CC} \
  -DCMAKE_CXX_COMPILER=${CXX} \
  -DSILO_ENABLE_SHARED=ON \
  -DSILO_ENABLE_HDF5=${SILO_HDF5} \
  -DSILO_ENABLE_FORTRAN=OFF \
  -DSILO_ENABLE_SILEX=OFF \
  -DSILO_ENABLE_BROWSER=ON \
  -DSILO_ENABLE_SILOCK=ON \
  -DSILO_ENABLE_PYTHON_MODULE=ON \
  -DPython_EXECUTABLE=${PYTHON} \
  -DSILO_BUILD_FOR_BSD_LICENSE=ON \
  $CMAKE_EXTRA
if [ $? != 0 ]; then
  echo "CMake configuration of Silo failed... quitting"
  exit 1
fi

echo "*** RUNNING MAKE ***"
cmake --build $BUILD_DIR -j $NCORES
if [ $? != 0 ]; then
  echo "Compilation of Silo failed... quitting"
  exit 1
fi

echo "*** INSTALLING SILO LIBRARY ***"
cmake --install $BUILD_DIR || exit 1

echo "********************************"
echo "*** Silo installed in ${PREFIX}"
echo "*** Python module: $(ls ${PREFIX}/lib/Silo*.so 2>/dev/null)"
echo "********************************"

# If a virtual environment is active, add a .pth file to it so that
# "import Silo" works without changing sys.path or PYTHONPATH.
if [ ! -z "$VIRTUAL_ENV" ]; then
  PTH=$($PYTHON -c "import pathlib, site; p = pathlib.Path(site.getsitepackages()[0]) / 'silo_local.pth'; p.write_text('${PREFIX}/lib\n'); print(p)")
  echo "*** Registered ${PREFIX}/lib with the virtual environment: ${PTH}"
  if $PYTHON -c "import Silo"; then
    echo "*** import Silo works."
  else
    echo "*** WARNING: import Silo failed; see the error above."
  fi
else
  echo "*** No virtual environment is active.  To use Silo from python, add"
  echo "*** ${PREFIX}/lib to sys.path or PYTHONPATH (see README.md)."
fi
