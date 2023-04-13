.DEFAULT_GOAL := build
.PHONY: build clean push
build:
	docker build --platform linux/amd64 -t libli/access:latest -t libli/access:0.2 .
push:
	@echo "Pushing to docker hub"
	docker login -u libli -p $(DOCKER_PASSWORD)
	docker push libli/access -a
clean:
	docker rmi libli/access:latest