include setenv.sh

prepare_env: build_ex_docker create_index_volume

build_ex_docker:
	docker build --no-cache -t sample_search_ex -f docker/Dockerfile.ex .

create_index_volume:
	docker volume create es-data

run_ex_docker:
	docker run \
	-it \
	--rm \
	-p $(APP_PORT1):$(APP_PORT1) \
	-p $(APP_PORT2):$(APP_PORT2) \
	-p $(JUPYTER_PORT):$(JUPYTER_PORT) \
	-e ENVIRONMENT=$(ENVIRONMENT) \
	-e QUEUERY_TOKEN=$(QUEUERY_TOKEN) \
	-e QUEUERY_TOKEN_SECRET=$(QUEUERY_TOKEN_SECRET) \
	-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	-v $(PWD):/work \
	-v es-data:/var/lib/elasticsearch \
	-v $(PWD)/elasticsearch_configs:/etc/elasticsearch \
	sample_search_ex \
	/bin/bash

remove_index_volume:
	docker volume rm es-data

build_prod_docker:
	docker build --no-cache -t sample_search_prod -f docker/Dockerfile.prod .

run_job_docker:
	docker run \
	-it \
	--rm \
	-p $(APP_PORT1):$(APP_PORT1) \
	-p $(APP_PORT2):$(APP_PORT2) \
	-e ENVIRONMENT=$(ENVIRONMENT) \
	-e QUEUERY_TOKEN=$(QUEUERY_TOKEN) \
	-e QUEUERY_TOKEN_SECRET=$(QUEUERY_TOKEN_SECRET) \
	-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	-e DEBUG=${DEBUG} \
	sample_search_prod \
	/bin/bash /work/bin/create_index_job.sh

run_app_docker:
	docker run \
	-it \
	--rm \
	-p $(APP_PORT1):$(APP_PORT1) \
	-p $(APP_PORT2):$(APP_PORT2) \
	-e ENVIRONMENT=$(ENVIRONMENT) \
	-e QUEUERY_TOKEN=$(QUEUERY_TOKEN) \
	-e QUEUERY_TOKEN_SECRET=$(QUEUERY_TOKEN_SECRET) \
	-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	sample_search_prod \
	/work/bin/start_app.sh
