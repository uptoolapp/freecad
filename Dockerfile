FROM ubuntu:22.04
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common wget curl gnupg2 build-essential cmake git \
    libboost-all-dev libeigen3-dev libgmp-dev libhdf5-dev libmedc-dev \
    libocct-data-exchange-dev libocct-foundation-dev libocct-modeling-algorithms-dev \
    libocct-visualization-dev libproj-dev libpython3.10-dev python3.10 python3.10-dev \
    python3.10-venv python3-pivy && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone the FreeCAD source
WORKDIR /tmp
RUN git clone --branch 0.21.2 --depth 1 https://github.com/FreeCAD/FreeCAD.git

# Build headless FreeCAD
WORKDIR /tmp/FreeCAD/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release \
             -DBUILD_GUI=OFF \
             -DBUILD_QT5=OFF \
             -DPYTHON_EXECUTABLE=/usr/bin/python3.10 \
             -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make -j$(nproc) && make install

# Clean up unnecessary files
RUN apt-get remove -y build-essential cmake git && apt-get autoremove -y && \
    rm -rf /tmp/* /var/lib/apt/lists/*

# Set PYTHONPATH for FreeCAD
ENV PYTHONPATH=/usr/local/Mod
