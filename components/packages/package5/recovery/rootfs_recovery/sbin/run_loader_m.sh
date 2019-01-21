#!/sbin/busybox ash
####!/sbin/busybox sh

echo "******** We are starting from loader_m now, seems should execute loader_m tool."
#sleep 2

device_node_dir="/dev/block"
mount_dir="/mnt/usb"
MOUNT_DEVICE_NODE=
to_run_loader_m=0

remove_action() {
        umount ${1}
        rm -rf ${2}
}

try_mount() {
	echo "In try_mount: ${MOUNT_DEVICE_MODE}"
	busybox mount -t vfat ${MOUNT_DEVICE_NODE} ${mount_dir}
}


# run loader_m
#if [ "/sbin/busybox ls ${mount_dir} | /sbin/busybox wc -l" -gt 0]; then
	echo "******** Finally, /sbin/loader_m is starting running."
	#/sbin/loader_m > /dev/console 2>&1
	/sbin/loader_m 
#fi 
