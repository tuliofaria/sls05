PACKAGE_DIR=package/package
ARTIFACT_NAME=package.zip
ARTIFACT_PATH=package/$(ARTIFACT_NAME)
ifdef DOTENV
	DOTENV_TARGET=dotenv
else
	DOTENV_TARGET=.env
endif
ifdef GO_PIPELINE_NAME
	ENV_RM_REQUIRED?=rm_env
endif
ifdef AWS_ROLE
	ASSUME_REQUIRED?=assumeRole
endif

################
# Entry Points #
################

build: $(DOTENV_TARGET)
	docker-compose run --rm serverless make _build

fast_build: $(DOTENV_TARGET)
	docker-compose run --rm serverless make _fast_build

deploy: $(ENV_RM_REQUIRED) $(ARTIFACT_PATH) $(DOTENV_TARGET) $(ASSUME_REQUIRED)
	docker-compose run --rm serverless make _deploy

remove: $(DOTENV_TARGET) $(ASSUME_REQUIRED)
	docker-compose run --rm serverless make _remove

shell: $(DOTENV_TARGET)
	docker-compose run --rm --service-ports serverless bash

##########
# Others #
##########

# Create .env based on .env.template if .env does not exist
.env:
	@echo "Create .env with .env.template"
	cp .env.template .env

# Create/Overwrite .env with $(DOTENV)
dotenv:
	@echo "Overwrite .env with $(DOTENV)"
	cp $(DOTENV) .env

rm_env:
	rm -f .env

# _deps installs nodejs modules.
# This is time consuming and if you are developing using a container, best to not exit the container.
_deps:
	yarn
	zip -rq node_modules.zip node_modules/

_test:
	yarn test

# _build installs nodejs production modules, and creates a package ready for Serverless Framework.
_build:
	mkdir -p $(PACKAGE_DIR)/
	cp -r src $(PACKAGE_DIR)/
	cp package.json $(PACKAGE_DIR)/
	cp yarn.lock $(PACKAGE_DIR)/
	cd $(PACKAGE_DIR) && yarn install --production
	cd $(PACKAGE_DIR) && zip -rq ../package .

# _fast_build does a pack but does not do the yarn install.
# This speeds up the process if you you have already done _build before and the node_modules production hasn't changed.
_fast_build:
	rm -fr $(PACKAGE_DIR)/src
	cp -r src $(PACKAGE_DIR)/src
	cd $(PACKAGE_DIR) && zip -rq ../package .
.PHONY: _buildLite

_deploy:
	rm -fr .serverless
	sls deploy -v

_remove:
	sls remove -v
	rm -fr .serverless

_clean:
	rm -fr node_modules node_modules.zip .serverless package
