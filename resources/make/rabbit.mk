RABBIT_DIR = deps/amqp_lib
RABBIT_SERVER_DIR = deps/rabbitmq-server
RABBIT_CODEGEN_DIR = deps/rabbitmq-codegen
RABBIT_URL = https://github.com/rabbitmq/

$(RABBIT_CODEGEN_DIR): ARCHIVE=archive/rabbitmq_v3_3_5.tar.gz
$(RABBIT_CODEGEN_DIR):
	@mkdir -p $(RABBIT_CODEGEN_DIR)
	@curl -L $(RABBIT_URL)/rabbitmq-codegen/$(ARCHIVE)| \
	tar xzC $(RABBIT_CODEGEN_DIR) --strip-components=1

$(RABBIT_SERVER_DIR): ARCHIVE=archive/rabbitmq_v3_3_5.tar.gz
$(RABBIT_SERVER_DIR):
	@mkdir -p $(RABBIT_SERVER_DIR)
	@curl -L $(RABBIT_URL)/rabbitmq-server/$(ARCHIVE)| \
	tar xzC $(RABBIT_SERVER_DIR) --strip-components=1


$(RABBIT_DIR): ARCHIVE=archive/rabbitmq_v3_3_5.tar.gz
$(RABBIT_DIR): $(RABBIT_SERVER_DIR) $(RABBIT_CODEGEN_DIR)
	@mkdir -p $(RABBIT_DIR)
	@curl -L $(RABBIT_URL)/rabbitmq-erlang-client/$(ARCHIVE)| \
	tar xzC $(RABBIT_DIR) --strip-components=1

compile-rabbit: $(RABBIT_DIR)
	@echo "Building RabbitMQ dependency ..."
	cd $(RABBIT_DIR) && \
	make compile
	mv deps/amqp_lib/deps/rabbit_common-0.0.0 deps/rabbit_common
	make clean-rabbit-deps

compile-proj:
	@echo "Compiling project code and dependencies ..."
	@which rebar.cmd >/dev/null 2>&1 && \
	PATH=$(SCRIPT_PATH) ERL_LIBS=$(ERL_LIBS) rebar.cmd compile || \
	PATH=$(SCRIPT_PATH) ERL_LIBS=$(ERL_LIBS) rebar compile

compile: get-deps clean-ebin compile-rabbit compile-proj

skip-rabbit: get-deps clean-ebin compile-proj

clean-rabbit-deps:
	rm -rf $(RABBIT_SERVER_DIR) $(RABBIT_CODEGEN_DIR)

clean-rabbit:
	@echo "Removing RabbitMQ dependency directory ..."
	rm -rf $(RABBIT_DIR)

clean: clean-ebin clean-eunit clean-rabbit
	@which rebar.cmd >/dev/null 2>&1 && rebar.cmd clean || rebar clean
