import pandas as pd
from utils import GetConfigs
from datetime import datetime
from pytz import timezone
from elasticsearch import Elasticsearch
import requests
from mldatautils.configs import GetConfigs

import json

es = Elasticsearch(['localhost'])

def extract_data(query):
    configs = GetConfigs('config.ini')
    engine = configs.create_engine()
    data = pd.read_sql_query(query, con=engine)
    data.to_csv('data.csv')
    return data

def create_json(df, index_name, create=True):
    with open(f'data/bulk_insert_{index_name}.ndjson', 'w', encoding='utf-8') as f:
        for i, row in df.iterrows():
            _id = row['id']
            data = row.drop('id')
            if i == 0 and create == True:
                action_and_meta_data = {"index": {"_index": f"{index_name}", "_id": _id}}
            else:
                action_and_meta_data = {"create": {"_index": f"{index_name}", "_id": _id}}
            json_string = data.to_json()
            f.write(str(action_and_meta_data).replace('\'', '"') + '\n')
            f.write(str(json_string) + '\n')
        f.write('\n')

def create_index_template(index_name):
    # create index_templatae
    headers={'Content-Type': 'application/json'}
    with open(f'index_templates/_index_template_{index_name}.json', 'r', encoding='utf-8') as f:
        json_string = json.load(f)
        print(json_string)
    res = requests.put(
        f'http://localhost:9200/_template/{index_name}_template',
        data = json.dumps(json_string),
        headers=headers)
    print(res)

def create_index(index_name):
    # create index
    with open(f'data/bulk_insert_{index_name}.ndjson', 'r', encoding='utf-8') as f:
        json_body = f.read()
    res = es.bulk(index=index_name, body=json_body)
    print(res)

def main():
    query = '''
    select col1 as field1, col2 as field2, col3 as date_field from sample_schema.sample_table
    '''
    data = extract_data(query)
    create_json(data, 'samples', create=True)
    create_index_template('samples')
    create_index('samples')


if __name__ == '__main__':
    main()
