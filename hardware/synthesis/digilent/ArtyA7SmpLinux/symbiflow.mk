# cd hardware/synthesis/digilent/ArtyA7SmpLinux/
# make generate
# export INSTALL_DIR=/opt/symbiflow
# export PATH="$INSTALL_DIR/xc7/install/bin:$PATH"
# source "$INSTALL_DIR/xc7/conda/etc/profile.d/conda.sh"
# conda activate xc7
# make -f symbiflow.mk
# conda deactivate

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(patsubst %/,%,$(dir $(mkfile_path)))
TOP:=ArtyA7SmpLinux
VERILOG:=${current_dir}/../../../netlist/$(TOP).v  ${current_dir}/../../xilinx/common/RamXilinx.v
BITSTREAM_DEVICE := artix7
SDC:=${current_dir}/ArtyA7.xdc
BUILDDIR:=build_symbiflow

PARTNAME:= xc7a35tcsg324-1
PCF:=${current_dir}/arty.pcf
DEVICE:= xc7a100t_test

all: ${BUILDDIR}/${TOP}.bit

${BUILDDIR}:
	mkdir ${BUILDDIR}

${BUILDDIR}/${TOP}.eblif: | ${BUILDDIR}
	cd ${BUILDDIR} && symbiflow_synth -t ${TOP} -v ${VERILOG} -d ${BITSTREAM_DEVICE} -p ${PARTNAME} 2>&1 > /dev/null

${BUILDDIR}/${TOP}.net: ${BUILDDIR}/${TOP}.eblif
	cd ${BUILDDIR} && symbiflow_pack -e ${TOP}.eblif -d ${DEVICE} -s ${SDC} 2>&1 > /dev/null

${BUILDDIR}/${TOP}.place: ${BUILDDIR}/${TOP}.net
	cd ${BUILDDIR} && symbiflow_place -e ${TOP}.eblif -d ${DEVICE} -p ${PCF} -n ${TOP}.net -P ${PARTNAME} -s ${SDC} 2>&1 > /dev/null

${BUILDDIR}/${TOP}.route: ${BUILDDIR}/${TOP}.place
	cd ${BUILDDIR} && symbiflow_route -e ${TOP}.eblif -d ${DEVICE} -s ${SDC} 2>&1 > /dev/null

${BUILDDIR}/${TOP}.fasm: ${BUILDDIR}/${TOP}.route
	cd ${BUILDDIR} && symbiflow_write_fasm -e ${TOP}.eblif -d ${DEVICE}

${BUILDDIR}/${TOP}.bit: ${BUILDDIR}/${TOP}.fasm
	cd ${BUILDDIR} && symbiflow_write_bitstream -d ${BITSTREAM_DEVICE} -f ${TOP}.fasm -p ${PARTNAME} -b ${TOP}.bit

clean:
	rm -rf ${BUILDDIR}