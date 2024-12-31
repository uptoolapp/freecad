FROM ubuntu:24.04 AS builder
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install build-time dependencies
RUN apt-get update
RUN apt-get install -y \
    cmake \
    debhelper-compat \
    dh-exec \
    dh-python \
    doxygen \
    git \
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
    libyaml-cpp-dev \
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

# Check out sources
WORKDIR /tmp
RUN git clone https://github.com/FreeCAD/FreeCAD.git
WORKDIR /tmp/FreeCAD
ENV FREECAD_VERSION=1.0.0
RUN git checkout $FREECAD_VERSION
RUN git submodule update --init

# Build & install
WORKDIR /tmp/FreeCAD/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_QT5=ON \
    -DCMAKE_INSTALL_PREFIX=/opt/freecad
RUN make -j$(nproc --ignore=1) VERBOSE=1
RUN make install

# Smoke test
WORKDIR /
ENV PATH=$PATH:/opt/freecad/bin
ENV PYTHONPATH=/opt/freecad/lib
RUN FreeCADCmd --version
RUN python3 -c "import FreeCAD; print(FreeCAD.newDocument())"

# Package
WORKDIR /tmp/packaging
RUN mkdir freecad-uptool
RUN mkdir -p freecad-uptool/opt && \
    cp -r /opt/freecad freecad-uptool/opt/
RUN mkdir -p freecad-uptool/usr/local/lib/python3.12/dist-packages && \
    cp -r /usr/local/lib/python3.12/dist-packages/freecad freecad-uptool/usr/local/lib/python3.12/dist-packages/
RUN mkdir freecad-uptool/DEBIAN
RUN cat <<EOF >freecad-uptool/DEBIAN/control
Package: freecad-uptool
Version: $FREECAD_VERSION
Architecture: all
Maintainer: Uptool Developers <developers@uptool.com>
Description: FreeCAD compiled from source for Ubuntu 24:04 LTS.
  Installed into /opt/freecad.
  Add /opt/freecad/bin to PATH.
  Add /opt/freecad/lib to PYTHONPATH.
Depends: libboost-date-time1.83.0,
         libboost-filesystem1.83.0,
         libboost-graph1.83.0,
         libboost-iostreams1.83.0,
         libboost-program-options1.83.0,
         libboost-python1.83.0,
         libboost-regex1.83.0,
         libboost-serialization1.83.0,
         libboost-thread1.83.0,
         libc6,
         libcoin80t64,
         libdouble-conversion3,
         libfmt9,
         libgcc-s1,
         libglew2.2,
         libgts-0.7-5t64,
         liblz4-1,
         libmedc11t64,
         libmetis5,
         libocct-data-exchange-7.6t64,
         libocct-ocaf-7.6t64,
         libocct-visualization-7.6t64,
         libpyside2-py3-5.15t64,
         libpython3.12t64,
         libqt5concurrent5t64,
         libqt5core5t64,
         libqt5gui5t64,
         libqt5opengl5t64,
         libqt5printsupport5t64,
         libqt5svg5 ,
         libqt5widgets5t64,
         libqt5x11extras5,
         libqt5xmlpatterns5,
         libshiboken2-py3-5.15t64,
         libspnav0,
         libstdc++6,
         libvtk9.1t64,
         libx11-6,
         libxerces-c3.2t64,
         libyaml-cpp0.8,
         libzipios++0v5,
         python3-matplotlib,
         python3-pivy,
         python3-ply,
         python3-pyside2.qtcore,
         python3-pyside2.qtgui,
         python3-pyside2.qtnetwork,
         python3-pyside2.qtsvg,
         python3-pyside2.qtuitools,
         python3-pyside2.qtwidgets,
         python3-pyside2.qtxml,
         python3-yaml
EOF
RUN dpkg-deb --build freecad-uptool

FROM ubuntu:24.04 AS tester
ENV DEBIAN_FRONTEND=noninteractive

# Install freecad
RUN apt-get update
COPY --from=builder /tmp/packaging/freecad-uptool.deb /tmp/freecad-uptool.deb
RUN apt-get install -y /tmp/freecad-uptool.deb
ENV PATH=$PATH:/opt/freecad/bin
ENV PYTHONPATH=/opt/freecad/lib

# Smoke test
RUN FreeCADCmd --version
RUN python3 -c "import FreeCAD; print(FreeCAD.newDocument())"

# Required for tests to pass
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y locales
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    dpkg-reconfigure locales && \
    /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LANG="en_US.UTF-8"

# Run tests (0 means all tests)
RUN FreeCADCmd --run-test 0
