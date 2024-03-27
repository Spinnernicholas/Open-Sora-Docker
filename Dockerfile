# Stage 1: Base
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04 as base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/London \
    PYTHONUNBUFFERED=1 \
    SHELL=/bin/bash

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        build-essential \
        software-properties-common \
        python3.10 \
        python3-pip \
        python3-tk \
        python3-dev \
        nodejs \
        npm \
        bash \
        dos2unix \
        git \
        git-lfs \
        ncdu \
        nginx \
        net-tools \
        inetutils-ping \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        zip \
        unzip \
        p7zip-full \
        htop \
        screen \
        tmux \
        bc \
        pkg-config \
        plocate \
        libcairo2-dev \
        libgoogle-perftools4 \
        libtcmalloc-minimal4 \
        apt-transport-https \
        ca-certificates && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Install Miniconda
RUN mkdir -p ~/miniconda3 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh && \
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 && \
    rm -rf ~/miniconda3/miniconda.sh

# Set Python
RUN ln -s /usr/bin/python3.10 /usr/bin/python

# Set Conda
RUN ln -s ~/miniconda3/bin/conda /usr/bin/conda

# Stage 2: Setup Application
FROM base as setup

WORKDIR /

# Create a virtual env
RUN conda create -y -n opensora python=3.10

# Install torch
# the command below is for CUDA 12.1, choose install commands from 
# https://pytorch.org/get-started/locally/ based on your own CUDA version
RUN ~/miniconda3/envs/opensora/bin/pip install torch torchvision

# Install flash attention (optional)
RUN ~/miniconda3/envs/opensora/bin/pip install packaging ninja
RUN ~/miniconda3/envs/opensora/bin/pip install flash-attn --no-build-isolation

# Install apex (optional)
RUN ~/miniconda3/envs/opensora/bin/pip install -v --disable-pip-version-check --no-cache-dir --no-build-isolation --config-settings "--build-option=--cpp_ext" --config-settings "--build-option=--cuda_ext" git+https://github.com/NVIDIA/apex.git

# Install xformers
RUN ~/miniconda3/envs/opensora/bin/pip install -U xformers --index-url https://download.pytorch.org/whl/cu121

# Install this project
RUN git clone https://github.com/hpcaitech/Open-Sora
WORKDIR /Open-Sora
RUN ~/miniconda3/envs/opensora/bin/pip install -v .

# Install gradio
RUN ~/miniconda3/envs/opensora/bin/pip install gradio

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/502.html /usr/share/nginx/html/502.html

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Copy the scripts
WORKDIR /
COPY --chmod=755 scripts/* ./

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]