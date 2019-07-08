#!/bin/bash

echo "download index from s3"
./bin/import_index_from_s3.sh
echo "start Elasticsearch"
./bin/start-elasticsearch.sh
echo "elasticsearch is started"
sudo tail -F /var/log/elasticsearch/sample-searcher.log
