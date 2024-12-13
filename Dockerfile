FROM ubuntu:24.04
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update
RUN apt-get install -y \
    cmake \
    debhelper-compat \
    dh-exec \
    dh-python \
    doxygen \
    libboost-date-time-dev \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-iostreams-dev \
    libboost-program-options-dev \
    libboost-python-dev \
    libboost-regex-dev \
    libboost-serialization-dev \
    libboost-thread-dev \
    libcoin-dev \
    libdouble-conversion-dev \
    libeigen3-dev \
    libfmt-dev \
    libglew-dev \
    libgts-bin \
    libgts-dev \
    libkdtree++-dev \
    liblz4-dev \
    libmedc-dev \
    libmetis-dev \
    libocct-data-exchange-dev \
    libocct-ocaf-dev \
    libocct-visualization-dev \
    libopencv-dev \
    libpyside2-dev \
    libqt5opengl5-dev \
    libqt5svg5-dev \
    libqt5x11extras5-dev \
    libqt5xmlpatterns5-dev \
    libshiboken2-dev \
    libspnav-dev \
    libvtk9-dev \
    libx11-dev \
    libxerces-c-dev \
    libzipios++-dev \
    lsb-release \
    occt-draw \
    pybind11-dev \
    pyqt5-dev-tools \
    pyside2-tools \
    python3-dev \
    python3-matplotlib \
    python3-pivy \
    python3-ply \
    python3-pyside2.qtcore \
    python3-pyside2.qtgui \
    python3-pyside2.qtnetwork \
    python3-pyside2.qtsvg \
    python3-pyside2.qtuitools \
    python3-pyside2.qtwidgets \
    python3-pyside2.qtxml \
    python3-requests \
    python3-yaml     \
    qtbase5-dev \
    qttools5-dev \
    qtwebengine5-dev \
    swig

# TODO: deduplicate above

RUN apt-get install -y git

# Build FreeCAD from source
WORKDIR /tmp
RUN git clone https://github.com/FreeCAD/FreeCAD.git
WORKDIR /tmp/FreeCAD
RUN git checkout 1.0.0
RUN git submodule update --init

# Create a build directory
RUN mkdir build
WORKDIR /tmp/FreeCAD/build

RUN apt-get install -y libyaml-cpp-dev

# Configure the build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_QT5=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local

# Build and install FreeCAD
RUN make -j$(nproc --ignore=1) VERBOSE=1
RUN make install

# Set PYTHONPATH for FreeCAD
ENV PYTHONPATH=/usr/local/lib

WORKDIR /
RUN FreeCADCmd --version
RUN python3 -c "import FreeCAD; print(FreeCAD.newDocument())"

# List tests
#RUN python3 -c "import FreeCAD; print(FreeCAD.__unit_test__)"; false

RUN FreeCADCmd --console --run-test TestAddonManagerApp
RUN FreeCADCmd --console --run-test TestAssemblyWorkbench
RUN FreeCADCmd --console --run-test TestDraft
RUN FreeCADCmd --console --run-test TestFemApp
#RUN FreeCADCmd --console --run-test TestMaterialsApp # UnicodeEncodeError: 'ascii' codec can't encode character '\xb5' in position 34: ordinal not in range(128)
RUN FreeCADCmd --console --run-test MeshTestsApp
RUN FreeCADCmd --console --run-test TestPartApp
RUN FreeCADCmd --console --run-test TestPartDesignApp
RUN FreeCADCmd --console --run-test TestCAMApp
RUN FreeCADCmd --console --run-test TestSketcherApp
RUN FreeCADCmd --console --run-test TestSpreadsheet
RUN FreeCADCmd --console --run-test TestSurfaceApp
RUN FreeCADCmd --console --run-test TestTechDrawApp
#RUN FreeCADCmd --console --run-test BaseTests # AssertionError: 'ascii' != 'utf-8'
RUN FreeCADCmd --console --run-test UnitTests
RUN FreeCADCmd --console --run-test Document
RUN FreeCADCmd --console --run-test Metadata
RUN FreeCADCmd --console --run-test StringHasher
RUN FreeCADCmd --console --run-test UnicodeTests
RUN FreeCADCmd --console --run-test TestPythonSyntax

# Make sure importing from python works
RUN python3 -c "import FreeCAD; import Mesh"