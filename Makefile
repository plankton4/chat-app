PROTO_DIR = ../chat-app-proto
SWIFT_OUT_DIR = SourceProto 

SWIFT_OUT_BUILD:
	@echo "Сборка swift протоколов"
	protoc -I=$(PROTO_DIR) --swift_out=$(SWIFT_OUT_DIR) $(PROTO_DIR)/common.proto
	
