MINBOT_IMAGE_NAME ?= minishift-bot/minibot
MINIBOT_VERSION = 0.9.0

# Variables needed to run Minibot
MINIBOT_IRC_TEST_CHANNEL ?= "\#minishift-test"
MINIBOT_ADMINS ?= hardy

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
	docker build -t $(MINBOT_IMAGE_NAME) .

run: build
	@:$(call check_defined, MINIBOT_REDIS_URL, "The build requires REDIS_URL to be set")
	@:$(call check_defined, MINIBOT_IRC_PASS, "The build requires MINIBOT_IRC_PASS to be set")
	docker run --rm -p 9009:9009 -e HUBOT_IRC_ROOMS=$(MINIBOT_IRC_TEST_CHANNEL) -e HUBOT_AUTH_ADMIN=$(MINIBOT_ADMINS) -e HUBOT_IRC_PASSWORD=$(MINIBOT_IRC_PASS) -e REDISTOGO_URL=$(MINIBOT_REDIS_URL) -t $(MINBOT_IMAGE_NAME)

clean:
	docker stop $(shell docker ps -a -q) && docker rm $(shell docker ps -a -q)

tag: build
	docker tag $(MINBOT_IMAGE_NAME) $(MINBOT_IMAGE_NAME):$(MINIBOT_VERSION)

push: tag
	docker push $(MINBOT_IMAGE_NAME)
