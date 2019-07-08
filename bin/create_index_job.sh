#!/bin/bash

echo "start Elasticsearch"
./bin/start-elasticsearch.sh
echo "sleep 60 s"
sleep 60
echo "create index"
/home/ubuntu/.rbenv/shims/bundle exec ruby src/create_index.rb
echo "stop Elasticsearch"
./bin/stop-elasticsearch.sh
if ! [[ ${DEBUG} -eq 1 ]]; then
  echo "sleep 30 s"
  sleep 30
  echo "export index to s3"
  ./bin/export_index_to_s3.sh
fi
