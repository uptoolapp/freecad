FROM ubuntu:24.04
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository --enable-source ppa:freecad-maintainers/freecad-daily && apt-get update
RUN apt-get build-dep -y freecad-daily

RUN git clone --recurse-submodules https://github.com/FreeCAD/FreeCAD.git freecad-source

WORKDIR /freecad-source
RUN git checkout 1.0.0

WORKDIR /freecad-build

RUN cmake -DPYTHON_EXECUTABLE=/usr/bin/python3 -DFREECAD_USE_PYBIND11=ON ../freecad-source
RUN make -j$(nproc --ignore=2)

RUN uname -m > /arch.txt