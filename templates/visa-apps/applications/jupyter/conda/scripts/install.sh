#!/bin/bash

CONDA_INSTALL_DIR=/opt/conda
CONDA_EXE=$CONDA_INSTALL_DIR/bin/conda

echo "Installing Conda..."
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
bash /tmp/miniconda.sh -b -p $CONDA_INSTALL_DIR
echo "Finished installing Conda"

echo "Configuring Conda..."
$CONDA_EXE install -y -c anaconda setuptools
$CONDA_EXE update -y conda

source "$CONDA_INSTALL_DIR/etc/profile.d/conda.sh"
echo "Configured Conda"
