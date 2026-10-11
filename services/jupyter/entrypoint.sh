#!/bin/bash
set -e

/opt/spark/sbin/start-history-server.sh &

jupyter lab --config=/etc/jupyter/jupyter_server_config.py \
            --port=8888 \
            --no-browser \
            --notebook-dir=/home/sparkuser \
            --LabApp.default_url='/lab'
wait