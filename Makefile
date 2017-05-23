.PHONY: all create build start stop download help

all: help

create:
	@if [ -z ${project} ] ; \
	then \
		echo "Please specify the project to create."; \
		echo "  make create project=[project-name]"; \
		echo "Stopping."; \
		exit 1; \
	fi;
	@if [ -d ./projects/$(project) ] ; \
	then \
		echo "Cannot create project - it already exists.  Stopping."; \
		echo "Look in ./projects/$(project)"; \
		exit 1; \
	fi;
	@echo "creating $(project)"
	@mkdir -p ./projects/ && cp -R environment_template ./projects/$(project)

build:
	@if [ ! -d ./projects/$(project) ] ; \
	then \
		echo "Project does not exist.  Stopping."; \
		exit 1; \
	fi;

	@if [ -d ./projects/$(project)/www ] ; \
	then \
		echo "Project 'www' directory already exists.  Not building."; \
		exit 1; \
	fi;

	@if [ ! -f ./projects/$(project)/build.sh ] ; \
	then \
		echo "No 'build.sh' file to execute and build the 'www' directory.  Stopping."; \
		exit 1; \
	fi;

	mkdir -p ./projects/$(project)/build; \
	cp ./projects/$(project)/build.sh ./projects/$(project)/build; \
	cd ./projects/$(project)/build && ./build.sh && mv www ../;

start:
	@if [ -z ${project} ]; then echo "Specify the project:\n make start project=[project]"; exit 1; fi
	@cd ./projects/$(project) && docker-compose up &

stop:
	@if [ -z ${project} ]; then echo "Specify the project:\n make start project=[project]"; exit 1; fi
	@cd ./projects/$(project) && docker-compose down &

download:
	@if [ -z ${project} ]; then echo "Specify the project:\n make download project=[project]"; exit 1; fi
	@echo Let us download

	rm -f ./projects/$(project)/download_exec.sh

	@cd ./projects/$(project); while read -r file; \
	do echo "Starting\n$$file"; \
		echo "docker-compose run --rm --entrypoint=/$$file" >> download_exec.sh ; \
	done <download.sh
	chmod u+x ./projects/$(project)/download_exec.sh
	cd ./projects/$(project)/; ./download_exec.sh ; rm ./download_exec.sh

help:
	@echo "=============================================================================="
	@echo " Vector Tile Downloader https://github.com/OrdnanceSurvey/vt-map-package"
	@echo " "
	@echo "Hints for developers:"
	@echo "  make create project=[project-name]   # create a new project"
	@echo "  make build project=[project-name]    # build project "
	@echo "  make start project=[project-name]    # start project "
	@echo "  make stop project=[project-name]     # stop project "
	@echo "  make download project=[project-name] # create offline map package "
	@echo " "
	@echo " Note: you may find it easiest to define a 'project' environment variable."
	@echo " "
	@echo "       e.g. export project=my-project"
	@echo " "
	@echo " Then you can ignore the project argument in the above commands."
	@echo "=============================================================================="
