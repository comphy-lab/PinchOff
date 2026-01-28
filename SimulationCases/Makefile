# Load BASILISK from .project_config if present
PROJECT_CONFIG := ../.project_config
ifneq ($(wildcard $(PROJECT_CONFIG)),)
  BASILISK := $(shell . $(PROJECT_CONFIG) && echo $$BASILISK)
endif

# Fall back to environment variable if no config file
ifeq ($(strip $(BASILISK)),)
  $(error "BASILISK not set; create $(PROJECT_CONFIG) or export BASILISK")
endif

CFLAGS += -O2 -disable-dimensions
CFLAGS += -I$(PWD)/src-local -I$(PWD)/../src-local

include $(BASILISK)/Makefile.defs
