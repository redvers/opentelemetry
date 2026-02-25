config ?= release

GET_DEPENDENCIES_WITH := corral fetch
CLEAN_DEPENDENCIES_WITH := corral clean
COMPILE_WITH := corral run -- ponyc

BUILD_DIR ?= build/$(config)
TEST_SRC_DIR := otel_test
tests_binary := $(BUILD_DIR)/otel_test
docs_dir := build/opentelemetry-pony-docs

ifdef config
	ifeq (,$(filter $(config),debug release))
		$(error Unknown configuration "$(config)")
	endif
endif

ifeq ($(config),release)
	PONYC = ${COMPILE_WITH}
else
	PONYC = ${COMPILE_WITH} --debug
endif

ifeq (,$(filter $(MAKECMDGOALS),clean docs realclean TAGS))
  ifeq ($(ssl), 3.0.x)
	  SSL = -Dopenssl_3.0.x
  else ifeq ($(ssl), 1.1.x)
	  SSL = -Dopenssl_1.1.x
  else ifeq ($(ssl), libressl)
	  SSL = -Dlibressl
  else
    $(error Unknown SSL version "$(ssl)". Must set using 'ssl=FOO')
  endif
endif

SOURCE_FILES := $(shell find otel_api otel_sdk otel_otlp otel_test -name \*.pony)

test: $(tests_binary)
	$^

$(tests_binary): $(SOURCE_FILES) | $(BUILD_DIR)
	${GET_DEPENDENCIES_WITH}
	${PONYC} ${SSL} -o ${BUILD_DIR} $(TEST_SRC_DIR)

check-api: | $(BUILD_DIR)
	${GET_DEPENDENCIES_WITH}
	${PONYC} ${SSL} --pass=expr -o ${BUILD_DIR} otel_api

check-sdk: | $(BUILD_DIR)
	${GET_DEPENDENCIES_WITH}
	${PONYC} ${SSL} --pass=expr -o ${BUILD_DIR} otel_sdk

check-otlp: | $(BUILD_DIR)
	${GET_DEPENDENCIES_WITH}
	${PONYC} ${SSL} --pass=expr -o ${BUILD_DIR} otel_otlp

check: check-api check-sdk check-otlp

clean:
	${CLEAN_DEPENDENCIES_WITH}
	rm -rf build

$(docs_dir): $(SOURCE_FILES)
	rm -rf $(docs_dir)
	${GET_DEPENDENCIES_WITH}
	${PONYC} --docs-public --pass=docs --output build otel_api

docs: $(docs_dir)

TAGS:
	ctags --recurse=yes otel_api otel_sdk otel_otlp

all: test

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: all clean check check-api check-sdk check-otlp docs TAGS test
