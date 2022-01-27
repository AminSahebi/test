CURRENT_DIR = $(PWD)
VPP := $(XILINX_VITIS)/bin/v++
EMCONFIGUTIL := $(XILINX_VITIS)/bin/emconfigutil
MODE := hw
#MODE := hw_emu

PLATFORM := xilinx_u250_gen3x16_xdma_3_1_202020_1

app := kernel_pagerank_0

#include utils.mk


HOST_SRC := $(CURRENT_DIR)/host/host.cpp #$(CURRENT_DIR)/host/xcl2.cpp
KRNL_SRC := $(CURRENT_DIR)/fpga/pagerank_kernel.cpp

# kernel targets
XOS := kernel_pagerank_0.$(MODE).xo
XCLBIN := kernel_pagerank_0.$(MODE).xclbin

# host target
#HOST_EXE := host.exe

EMCONFIG_FILE := emconfig.json

#Compiler flags
VPP_COMMON_OPTS := -s -t $(MODE) --platform $(PLATFORM) 
#vPP_COMM_OPT += -g --profile.data all:all:all

VPP_LINK_OPTS :=  --config connectivity.cfg
CFLAGS := -std=c++14 -I$(XILINX_XRT)/include -I${XILINX_VIVADO}/include -I$(CURRENT_DIR)/utils
#CLAGS += -g

VPP_COMMON_OPTS += --hls.jobs 8
VPP_COMMON_OPTS += --vivado.synth.jobs 8 --vivado.impl.jobs 8
#VPP_COMMON_OPTS += --optimize 3

LFLAGS := -L$(XILINX_XRT)/lib -lxilinxopencl -lpthread -lrt

#Run time arguments
EXE_OPT := $(app).$(MODE).xclbin

# primary build targets
.PHONY: xclbin kernel_pagerank_0 all clean

xclbin:  $(XCLBIN)
#app: $(HOST_EXE)

all: xclbin app

clean:
	rm -rf $(EMCONFIG_FILE) $(app) _x .ipcache

# kernel rules
$(XOS): $(KRNL_SRC)
	$(VPP) $(VPP_COMMON_OPTS) -c -k $(app) -o $@ $+


$(XCLBIN): $(XOS)
	$(VPP) $(VPP_COMMON_OPTS) -l -o  $@ $+ $(VPP_LINK_OPTS)

# host rules
$(app): $(HOST_SRC)
	g++ $(CFLAGS) -o $@ $+ $(LFLAGS)
	@echo 'Compiled Host Executable: $(app)'

$(EMCONFIG_FILE):
	$(EMCONFIGUTIL) --nd 1 --od . --platform $(DSA)

check: $(XCLBIN) $(HOST_EXE) $(EMCONFIG_FILE)
	XCL_EMULATION_MODE=${MODE} ./$(app) $(EXE_OPT)
