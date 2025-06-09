IMAGE_NAME ?= go-server
IMAGE_TAG ?= v1.0.0
DOCKER_USERNAME ?= leoliu1988
PORT ?= 8080
HOST_PORT ?= 8080
TEST_SERVER ?= test_server

clean-build:
	rm -rf ./build/go-server

build: clean-build
	go build -o ./build/$(IMAGE_NAME) . 

build-img:
	docker build -t $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG) .

push-img:
	docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG)

remove-test-container:
	docker stop $(TEST_SERVER)
	docker rm $(TEST_SERVER)

run-test: remove-test-container
	docker run -d --restart always --name=$(TEST_SERVER) -e LISTEN_PORT=$(PORT) -p $(HOST_PORT):$(PORT) $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG)

network-debug:
	docker run -it --net container:$(TEST_SERVER) nicolaka/netshoot