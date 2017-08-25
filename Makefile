MINIBOT_IMAGE_NAME ?= minishift/minibot
MINIBOT_VERSION = 1.2.1

# Variables needed to run Minibot
MINIBOT_IRC_TEST_CHANNEL ?= "\#minishift-test"
MINIBOT_ADMINS ?= hardy

# Optional
MINIBOT_OPTS=-e MINIBOT_LOG_WEBHOOKS=true

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

build:
	docker build -t $(MINIBOT_IMAGE_NAME) .

run: build
	@:$(call check_defined, MINIBOT_REDIS_URL, "The build requires REDIS_URL to be set")
	@:$(call check_defined, MINIBOT_IRC_PASS, "The build requires MINIBOT_IRC_PASS to be set")
	docker run --rm -p 9009:9009 -e HUBOT_IRC_ROOMS=$(MINIBOT_IRC_TEST_CHANNEL) \
	-e HUBOT_AUTH_ADMIN=$(MINIBOT_ADMINS) \
	-e HUBOT_IRC_PASSWORD=$(MINIBOT_IRC_PASS) \
	-e REDISTOGO_URL=$(MINIBOT_REDIS_URL) \
	$(MINIBOT_OPTS) \
	-t $(MINIBOT_IMAGE_NAME)

clean:
	docker stop $(shell docker ps -a -q) && docker rm $(shell docker ps -a -q)

tag: build
	docker tag $(MINIBOT_IMAGE_NAME) $(MINIBOT_IMAGE_NAME):$(MINIBOT_VERSION)

push: tag
	docker push $(MINIBOT_IMAGE_NAME)
