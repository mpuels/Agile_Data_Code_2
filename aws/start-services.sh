#!/usr/bin/env bash

set -euo pipefail

cd /home/ubuntu/Agile_Data_Code_2
jupyter-notebook --ip=0.0.0.0 &

/home/ubuntu/elasticsearch/bin/elasticsearch -d
