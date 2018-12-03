#!/bin/bash

PACKAGE_BASE_DIR=`pwd`
echo "PACKAGE_BASE_DIR=".$PACKAGE_BASE_DIR
ROOTFS_DIR=$PACKAGE_BASE_DIR/rootfs_recovery
ROOTFS_DIR_TMP=$PACKAGE_BASE_DIR/rootfs_recovery_tmp
#ROOTFS_DIR=$PACKAGE_BASE_DIR/rootfs_android
LAYOUT=emmc

#IMG_SZ=4  #4MB  // rootfs android
IMG_SZ=12 #12MB 

#PKG_NAME="android" 
PKG_NAME="rescue" 

cp -rf $ROOTFS_DIR $ROOTFS_DIR_TMP
find $ROOTFS_DIR_TMP -name ".svn" | xargs rm -rf

chmod 644 $ROOTFS_DIR_TMP/default.prop
chmod 644 $ROOTFS_DIR_TMP/init.*
chmod 644 $ROOTFS_DIR_TMP/ueventd.*
chmod 755 $ROOTFS_DIR_TMP/init.rc
chmod 755 $ROOTFS_DIR_TMP/init

pushd $ROOTFS_DIR_TMP

find . | cpio --quiet -o -H newc > $PACKAGE_BASE_DIR/rootfs_$PKG_NAME.cpio

popd

gzip -9 -c $PACKAGE_BASE_DIR/rootfs_$PKG_NAME.cpio > $PACKAGE_BASE_DIR/rootfs_$PKG_NAME.cpio.gz

dd if=/dev/zero of=$PACKAGE_BASE_DIR/pad.img bs=1M count=$IMG_SZ
cat $PACKAGE_BASE_DIR/rootfs_$PKG_NAME.cpio.gz $PACKAGE_BASE_DIR/pad.img > $PACKAGE_BASE_DIR/temp.img

#dd if=$PACKAGE_BASE_DIR/temp.img of=$PACKAGE_BASE_DIR/rootfs_$PKG_NAME.cpio.gz_pad.img bs=1M count=$IMG_SZ
dd if=$PACKAGE_BASE_DIR/temp.img of=$PACKAGE_BASE_DIR/$PKG_NAME.root.$LAYOUT.cpio.gz_pad.img bs=1M count=$IMG_SZ

#rm -f temp.img pad.img rootfs_$PKG_NAME.cpio.gz rootfs/rootfs_$PKG_NAME.cpio
rm -f $PACKAGE_BASE_DIR/temp.img $PACKAGE_BASE_DIR/pad.img $PACKAGE_BASE_DIR/rootfs/rootfs_$PKG_NAME.cpio

rm -rf $PACKAGE_BASE_DIR/rootfs_recovery_tmp
