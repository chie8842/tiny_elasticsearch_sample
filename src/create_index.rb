require 'queuery_client'
require 'json'
require 'httpclient'
require 'elasticsearch'
require 'time'
require 'logger'

$log = Logger.new(STDOUT)

def init_queuery
  if ENV['QUEUERY_TOKEN'].length == 0 then
    $log.error("QUEUERY_TOKEN is invalid")
    exit 1
  else
    $log.debug(ENV['QUEUERY_TOKEN'][0, 3])
  end
  if ENV['QUEUERY_TOKEN_SECRET'].length == 0 then
    $log.error("QUEUERY_TOKEN_SECRET is invalid")
    exit 1
  else
    $log.debug(ENV['QUEUERY_TOKEN_SECRET'][0, 3])
  end
  RedshiftConnector.logger = Logger.new($stdout)
  GarageClient.configure do |config|
    config.name = "queuery-sample-search"
  end
  QueueryClient.configure do |config|
    config.endpoint = 'https://queuery_url/'
    config.token = ENV['QUEUERY_TOKEN']
    config.token_secret = ENV['QUEUERY_TOKEN_SECRET']
  end
  $log.info("Finished configure QueueryClient")
  QueueryClient
end

def extract_data(select_stmt, client)
  bundle = client.query(select_stmt)
  $log.info("#{select_stmt} is finished")
  bundle
end

def create_json(data, index_name, columns_data)
  filename = "data/bulk_insert_#{index_name}.ndjson"
  $log.info("create #{filename}")
  File.open(filename, "w") do |f|
    i = 0
    data.each do |row|
      id = row[0]
      action_and_meta_data = ""
      if i == 0 then
        action_and_meta_data = "{\"index\": {\"_index\": \"#{index_name}\", \"_id\": #{id}}}"
      else
        action_and_meta_data = "{\"create\": {\"_index\": \"#{index_name}\", \"_id\": #{id}}}"
      end
      row_hash = {}
      col_num = columns_data.keys.length
      col_num.times do |j|
        column = columns_data.keys[j]
        col_type = columns_data[column]['type']
        if col_type == 'date' then
          row_hash[column] = Time.parse(row[j+1]).to_i * 1000
        else
          row_hash[column] = row[j+1]
        end
      end
      f.puts(action_and_meta_data)
      f.puts(JSON.generate(row_hash))
      i += 1
    end
  end
  $log.info("#{filename} is created")
end

def create_index_template(index_name)
  $log.info("put #{index_name} template")
  headers = { 'Content-Type': 'application/json' }
  filename = "index_templates/_index_template_#{index_name}.json"
  json_data = File.open(filename) do |f|
    JSON.load(f)
  end
  client = HTTPClient.new
  url = "http://localhost:9200/_template/#{index_name}_template"
  p url
  p json_data
  client.put(url, json_data.to_json, 'Content-Type' => 'application/json')
  $log.info("finish putting #{index_name} template")
  columns_data = json_data['mappings']['properties']
  columns_data
end

def bulk_post(es_endpoint, data)
  $log.info("start bulk insert to #{es_endpoint}")
  c = Elasticsearch::Client.new log: true, url: es_endpoint
  c.bulk(body: data)
  $log.info("finish bulk insert to #{es_endpoint}")
end

def bulkload_index(index_name)
  $log.info("create #{index_name} index")
  filename = "data/bulk_insert_#{index_name}.ndjson"
  ndjson_data = File.open(filename) do |f|
    f.read
  end
  es_endpoint = "http://localhost:9200"
  bulk_post(es_endpoint, ndjson_data)
  $log.info("#{index_name} index is created")
end

def create_index(index_name, client)
  filename = "sql/#{index_name}.sql"
  select_stmt = File.open(filename) do |f|
    f.read
  end
  data = extract_data(select_stmt, client)
  columns_data = create_index_template(index_name)
  create_json(data, index_name, columns_data)
  bulkload_index(index_name)
end

def main
  # init QueueryClient
  client = init_queuery

  # create samples index
  create_index("samples", client)
end

main()
