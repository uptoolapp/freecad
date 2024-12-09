FROM ubuntu:22.04
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && \
    apt-get install -y software-properties-common wget curl gnupg2 gettext build-essential cmake git && \
    apt-get install -y libboost-date-time-dev libboost-filesystem-dev libboost-graph-dev libboost-iostreams-dev \
    libboost-program-options-dev libboost-python-dev libboost-regex-dev libboost-serialization-dev \
    libboost-system-dev libboost-thread-dev libcoin-dev libeigen3-dev libfontconfig1-dev libfreetype6-dev \
    libgmp-dev libhdf5-dev libmedc-dev libocct-data-exchange-dev libocct-foundation-dev libocct-modeling-algorithms-dev \
    libocct-visualization-dev libproj-dev libpython3.10-dev libqt5svg5-dev libqt5x11extras5-dev libshiboken2-dev \
    libspnav-dev libxerces-c-dev libxmu-dev libxmu-headers netgen occt-draw python3.10 python3.10-dev python3.10-distutils \
    python3.10-venv python3-pivy python3-ply python3-pyside2.qtcore python3-pyside2.qtgui python3-pyside2.qtsvg \
    python3-pyside2.qtwidgets python3-matplotlib libnglib-dev

RUN apt-get install -yqq  libvtk9-dev libvtk9-qt-dev \
    swig \
    qtbase5-dev \
    qtdeclarative5-dev \
    qt5-qmake \
    qttools5-dev-tools \
    qttools5-dev \
    qtwebengine5-dev \
    libqt5xmlpatterns5-dev

# Build FreeCAD from source
WORKDIR /tmp
RUN git clone https://github.com/FreeCAD/FreeCAD.git
WORKDIR /tmp/FreeCAD
RUN git checkout 0.21.2

# Create a build directory
RUN mkdir build
WORKDIR /tmp/FreeCAD/build

# Configure the build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_QT5=ON \
    -DPYTHON_EXECUTABLE=/usr/bin/python3.10 \
    -DCMAKE_INSTALL_PREFIX=/usr/local

# Build and install FreeCAD
RUN make -j$(nproc --ignore=1) VERBOSE=1
RUN make install

# Clean up build dependencies (optional)
RUN apt-get remove -y build-essential cmake git && apt-get autoremove -y

# Set PYTHONPATH for FreeCAD
ENV PYTHONPATH=/usr/local/Mod
