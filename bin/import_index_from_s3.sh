#!/bin/bash

NEWEST_VERSION=`aws s3 ls s3://bucket_name/${ENVIRONMENT}/search/index_data/|sed -e "s/\ \ //g"|cut -d " " -f 3 |sort -nr |head -n 1`
echo "sudo -Eu elasticsearch aws s3 sync s3://bucket_name/${ENVIRONMENT}/search/index_data/${NEWEST_VERSION}nodes /var/lib/elasticsearch/nodes"
sudo -Eu elasticsearch aws s3 sync s3://bucket_name/${ENVIRONMENT}/search/index_data/${NEWEST_VERSION}nodes /var/lib/elasticsearch/nodes
