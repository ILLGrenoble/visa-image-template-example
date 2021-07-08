#!/bin/bash 

CONDA_INSTALL_DIR=/opt/conda
CONDA_ENVS_DIR=$CONDA_INSTALL_DIR/envs
CONDA_EXE=$CONDA_INSTALL_DIR/bin/conda
JUPYTER_DIR=/opt/visa/jupyter

CONDA_ALWAYS_YES="true"

echo "Setting up conda environment for data analysis"

source "$CONDA_INSTALL_DIR/etc/profile.d/conda.sh"

$CONDA_EXE env create -f /tmp/environment_data_analysis.yml --force

echo "Creating ipykernel for data analysis"

$CONDA_ENVS_DIR/data-analysis/bin/python -m ipykernel install --prefix=$JUPYTER_DIR/jupyterlab --name 'python3' --display-name 'Data Analysis'

conda clean -a -f -y