image := groventure/sensu:latest

default: build

build: Dockerfile
	docker build --rm -t '$(image)' .
