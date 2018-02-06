#!/bin/sh

# adapted from https://gist.github.com/mitsuji/8397836
#
# ./create_vm.sh myvmname01 Downloads/SIMP-6.0.0-0-Powered-by-CentOS-7.0-x86_64.iso
#
# VBoxManage startvm vm1 -type headless
# VBoxManage unregistervm vm1 --delete

VM_NAME=$1
DVD_PATH=${2:---}
OS_TYPE=${3:-RedHat_64}
MEMORY_SIZE=${4:-3072}
HDD_SIZE=${5:-51200}
NUM_CPUS=${6:-2}
VRDE_PORT=${7:-3393}
PNIC=enp6s0

usage="${0} VM_NAME [DVD_PATH] [OS_TYPE] [MEMORY_SIZE] [HDD_SIZE] [NUM_CPUS] [VRDE_PORT]"

MACHINE_FOLDER=`VBoxManage list systemproperties | grep '^Default machine folder:' | cut -d: -f 2 | sed -e 's/^ *//g;s/ *$//g'`
HDD_PATH="${MACHINE_FOLDER}/${VM_NAME}/${VM_NAME}.vdi"
[[ -z "${1}" ]] && echo $usage && exit


VBoxManage showvminfo "${VM_NAME}" > /dev/null
if [[ $? -eq 0 ]]; then
  VBoxManage unregistervm "${VM_NAME}" --delete
  VBoxManage closemedium "${HDD_PATH}"
  echo ==================
  [[ -f "${HDD_PATH}" ]] && rm -f "${HDD_PATH}"
fi


VBoxManage createvm -name "${VM_NAME}" -ostype $OS_TYPE --register
[[ $? -eq 0 ]] || exit 1


VBoxManage modifyvm "${VM_NAME}" \
    --memory $MEMORY_SIZE \
    --cpus $NUM_CPUS \
    --vram 12 \
    --pae off \
    --rtcuseutc on \
    --nic1 natnetwork
#    --nic1 bridged --bridgeadapter1 $PNIC

[[ $? -eq 0 ]] || exit 1

VBoxManage createmedium disk --filename "${HDD_PATH}" --size $HDD_SIZE --format VDI
[[ $? -eq 0 ]] || exit 1

VBoxManage storagectl "${VM_NAME}" --name "IDE Controller" --add ide
[[ $? -eq 0 ]] || exit 1
VBoxManage storagectl "${VM_NAME}" --name "SATA Controller" --add sata
[[ $? -eq 0 ]] || exit 1

if [[ "${DVD_PATH}" != "--" ]]; then
  VBoxManage storageattach "${VM_NAME}" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "${DVD_PATH}"
  [[ $? -eq 0 ]] || exit 1
fi

VBoxManage storageattach "${VM_NAME}" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "${HDD_PATH}"
[[ $? -eq 0 ]] || exit 1


VBoxManage modifyvm "${VM_NAME}" \
        --audio none
###     --vrde on \
###     --vrdeaddress 127.0.0.1 \
###     --vrdeport $VRDE_PORT \
[[ $? -eq 0 ]] || exit 1

# Export OVF and delete VM
VBoxManage export "${VM_NAME}" --output "${VM_NAME}.ovf" --ovf20
VBoxManage unregistervm "${VM_NAME}" --delete
# TODO: I don't know if this deletes the disk

exit 0

