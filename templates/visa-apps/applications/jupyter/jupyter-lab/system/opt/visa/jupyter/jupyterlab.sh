#!/bin/bash

JUPYTER_ENV=/opt/visa/jupyter/jupyterlab

# Get owner and instance_id metadata
OWNER=`cloud-init query ds.meta_data.meta.owner`
INSTANCE_ID=`cloud-init query ds.meta_data.meta.id`

# The jupyter configuration file (you may want a different conf depending on dev or prod environments)
JUPYTER_CONF=/opt/visa/jupyter/jupyter-conf.py

if [ -z "$OWNER" ]; then
    echo "Failed to get OWNER from OpenStack instance metadata"
    exit 1
else
    echo "Got owner \"$OWNER\" from OpenStack instance metadata"
fi

if [ -z "$INSTANCE_ID" ]; then
    echo "Failed to get INSTANCE_ID from OpenStack instance metadata"
    exit 1
else
    echo "Got instance ID $INSTANCE_ID from OpenStack instance metadata"
fi

BASE_URL=/jupyter/$INSTANCE_ID

# Check that the owner/login exists
if ! id "$OWNER" &>/dev/null; then
    echo "Failed to run JupyerLab: User $OWNER not found"
    exit 1
fi

# Run as the instance owner
su - $OWNER <<EOF

echo "Running JupyterLab as $OWNER using conf file $CONF with base URL $BASE_URL"

# Run JupyterLab
$JUPYTER_ENV/bin/jupyter lab --config $JUPYTER_CONF --NotebookApp.base_url=$BASE_URL

EOF
