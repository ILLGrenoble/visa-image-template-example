#!/bin/bash

echo "Installing JupyterLab..."
JUPYTER_DIR=/opt/visa/jupyter

mkdir -p $JUPYTER_DIR
cd $JUPYTER_DIR || exit
python3 -m venv jupyterlab
source jupyterlab/bin/activate

pip install --upgrade pip

pip install jupyterlab==2.3.1
pip install ipywidgets==7.5.1

# enable h5web
pip install jupyterlab_h5web[full]==0.0.8
jupyter lab clean
jupyter lab build

# enable interactive matplotlib
jupyter labextension install @jupyter-widgets/jupyterlab-manager
jupyter labextension install jupyter-matplotlib@0.7.4
jupyter nbextension enable --py widgetsnbextension

jupyter lab clean

echo "Finished installing JupyterLab"
