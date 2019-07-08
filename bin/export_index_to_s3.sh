#!/bin/bash
CUR_DATE=`date "+%Y%m%d-%H%M"`
echo "sudo -E aws s3 sync /var/lib/elasticsearch/nodes s3://bucket_name/${ENVIRONMENT}/search/index_data/${CUR_DATE}/nodes"
sudo -E aws s3 sync /var/lib/elasticsearch/nodes s3://bucket_name/${ENVIRONMENT}/search/index_data/${CUR_DATE}/nodes
