# Python Library for PION
Created - 26|08|2019,
Modified - 13|11|2026

Welcome to the Python Library that does post-processing on the .Silo simulation data files outputted from PION. The library works on nested-grid and uniform-grid, and 3D and 2D Silo files.

# Installation

PyPion is installed from PyPI with `pip`, but it also needs the python module
of the [Silo library](https://github.com/LLNL/Silo), which is not on PyPI and
has to be compiled.  The script `src/silo/install_silo.sh` in this repository
does this.

Recent Linux distributions and Homebrew do not allow `pip install` into the
system python, so install PyPion in a virtual environment.

## 1. Install the build tools

* Debian/Ubuntu:
  ```bash
  sudo apt install build-essential cmake wget python3-dev python3-venv
  ```
* MacOS: install the Apple command-line tools (`xcode-select --install`) and
  [Homebrew](https://brew.sh/), then
  ```bash
  brew install python3 cmake wget
  ```

## 2. Create a virtual environment and install PyPion

```bash
python3 -m venv ~/pypion-venv
source ~/pypion-venv/bin/activate
python -m pip install --upgrade pip
python -m pip install pypion matplotlib
```

## 3. Compile and install Silo with its python module

With the virtual environment still active, run the install script in an empty
directory (it downloads and compiles Silo there; you can delete the directory
afterwards):

```bash
git clone https://github.com/greensh16/PyPion.git ~/PyPion
mkdir -p ~/.cache/silo-build && cd ~/.cache/silo-build
bash ~/PyPion/src/silo/install_silo.sh
```

This installs Silo in `~/.local/silo` (set `SILO_PREFIX` to change this), and
adds a file `silo_local.pth` to the virtual environment so that `import Silo`
works.  The python module only works with the python version it was compiled
for, so if you upgrade python or create a new virtual environment, run the
script again.

On Apple Silicon Macs, make sure that Homebrew, python and the terminal are
all native (`arm64`), not running under Rosetta.

## 4. Check the installation

```bash
python -c "import Silo; from pypion.ReadData import ReadData; print(Silo.__file__)"
```

Activate the virtual environment (`source ~/pypion-venv/bin/activate`) every
time you open a new terminal to use PyPion.

# Info on how to get started

* Installation and example usage are described in the PION documentation:
  [https://pion-docs-dev.readthedocs.io/en/latest/python.html](https://pion-docs-dev.readthedocs.io/en/latest/python.html)
* The relevant files can be found in `src/pypion`. You can use `PlotData.py`
  as a test script; it can call a 2D and a 3D function from
  `Plotting_Classes.py`. See the comments in the python script on how to use
  it and change it for your needs.


# Developers/Maintainers:

* Samuel Green - green@cp.dias.ie
* Jonathan Mackey

