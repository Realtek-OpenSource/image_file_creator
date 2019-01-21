#!/bin/bash
TOP_DIR=$(dirname $0)
echo "$TOP_DIR"
#CONFIG_FILE=$TOP_DIR/../../../../.build_config
UTILDIR=$TOP_DIR/../../../components/
TEEUTIDIR=$TOP_DIR/../../../components/tmp/pkgfile
TADIR=lib/teetz
SECURE_KEY_FILE=$TOP_DIR/../../../aes_128bit_key.bin
SECURE_KEY1_FILE=$TOP_DIR/../../../aes_128bit_key_1.bin
SECURE_KEY2_FILE=$TOP_DIR/../../../aes_128bit_key_2.bin
SECURE_KEY3_FILE=$TOP_DIR/../../../aes_128bit_key_3.bin
DO_SHA256_PATH=$UTILDIR/bin/do_sha256
RTSSL_PATH=$UTILDIR/bin/RtSSL
OBFUSE_2_PATH=$UTILDIR/bin/obfuse_0002


#SECURE_BOOT=`grep -n 'CONFIG_IMAGE_SECURE_OPTION ' $CONFIG_FILE| awk -F'CONFIG_IMAGE_SECURE_OPTION ' '{print $2}'`
SECURE_BOOT='on'
case $SECURE_BOOT in
 	"on")

	echo "Extract teeUltilty.tar ..."
	cp $TEEUTIDIR/teeUtility.tar .
	tar xf teeUtility.tar

	echo "ENC TAFILE BY KTEE.....";
	rm -rf $TADIR/*.enc;
	rm -f $TADIR*.padding;

	TAFILE=`find ./lib/teetz -name "*.ta"`

	for file in $TAFILE; do 
	echo "TA File: $file"; 
	$DO_SHA256_PATH $file $file.tmp.padding $file.tmp2.padding;
	cat $file $file.tmp.padding > $file.padding;
	$OBFUSE_2_PATH $RTSSL_PATH 93 $SECURE_KEY1_FILE $SECURE_KEY_FILE $SECURE_KEY2_FILE $SECURE_KEY3_FILE $file.padding $file.enc;
	#cp $file.enc .; cp $file .;
	rm -f $file*.padding; rm -f const_key_file.bin;
	done

	chmod 777 $TADIR/*.enc;

	echo "Package teeUltilty.tar ...";
	rm -f teeUtility.tar
	tar cvf teeUtility.tar bin lib lib64
	mv teeUtility.tar $TEEUTIDIR
	rm -rf bin lib lib64 
	echo "Encrypt teeUltilty.tar done.";
	;;

	"off")

	echo "skip to encrypt teeUltilty.tar ..."
	;;

	*)
	echo "Unkown secure type"
	exit 1
	;;
	esac 
