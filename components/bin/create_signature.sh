#!/bin/bash

TOP_DIR=$(dirname $0)

# tool
OPENSSL=openssl
CREATE_SIGN_EXE=$TOP_DIR/create_signature

# $(call hwrsa-sign, rsa_key_text, clear_data, enc_data)
function hwrsa-sign() {
	#$CREATE_SIGN_EXE $4 $5 $2 $6 $7;
	${OPENSSL} rsa -text -in $1 -out $1.text;
	${OPENSSL} rsautl -inkey $1 -sign -raw -in $2 -out $3;	
} 

echo "usage: create_signature.sh <length-of-file> <length-of-singing> <file-to-sign> <signature-file> <signed file> <key-file> <mode> <id-name>"
LENGTH_TO_FILE=$1
LENGTH_OF_SINGING=$2
FILE_TO_SIGN=$3
SIGNATURE_FILE=$4
SIGNED_FILE=$5
RSA_KEY_FILE=$6
MODE=$7
ID_NAME=$8

echo $LENGTH_TO_FILE
echo $LENGTH_OF_SINGING
echo $FILE_TO_SIGN
echo $SIGNATURE_FILE
echo $SIGNED_FILE
echo $RSA_KEY_FILE
echo $MODE
echo $ID_NAME

# sha256
${OPENSSL} dgst -sha256 -binary -out ${FILE_TO_SIGN}.digest ${FILE_TO_SIGN}

if [ ${RSA_KEY_FILE} == null ];
then
	echo "key null"
	${CREATE_SIGN_EXE} ${LENGTH_TO_FILE} ${LENGTH_OF_SINGING} ${FILE_TO_SIGN}.digest ${SIGNATURE_FILE} ${MODE};
	cat ${FILE_TO_SIGN} ${SIGNATURE_FILE} > ${SIGNED_FILE}
else
	echo "key has"
	${CREATE_SIGN_EXE} ${LENGTH_TO_FILE} ${LENGTH_OF_SINGING} ${FILE_TO_SIGN}.digest ${SIGNATURE_FILE} ${MODE};
	hwrsa-sign ${RSA_KEY_FILE} ${SIGNATURE_FILE} ${FILE_TO_SIGN}.digest.enc
	mv ${FILE_TO_SIGN}.digest.enc ${SIGNATURE_FILE}
	cat ${FILE_TO_SIGN} ${SIGNATURE_FILE} > ${SIGNED_FILE}
fi

