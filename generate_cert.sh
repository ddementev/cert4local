#!/bin/bash

while [ -z $DOMAIN ]; do
	echo -n "Please enter the domain name for generating the self-signed certificate: ";
	read DOMAIN;
done;

outdir='./out/';
if [ ! -d $outdir ]
then
	mkdir $outdir;
fi

COMMON_NAME="self-signed"
SUBJECT="/C=RU/ST=Russia/L=MituleVillage/O=MyOrganisation/CN=$COMMON_NAME"
NUM_OF_DAYS=999
if [ ! -f ${outdir}rootCA.key ]
then
	echo "Generating the private key for the root CA....";
	openssl genrsa -out ${outdir}rootCA.key 2048	
	echo "Done.";
fi

if [ ! -f ${outdir}rootCA.pem ] 
then
	echo "Generating the certificate for the root CA....";
	openssl req -x509 -new -nodes -key ${outdir}rootCA.key -sha256 -days 1024 -subj "$SUBJECT" -out ${outdir}rootCA.pem
	echo "Done.";
fi

echo "Generating the private key of the certificate....";
openssl req -new -newkey rsa:4096 -sha256 -nodes -keyout ${outdir}device.key -subj "$SUBJECT" -out ${outdir}device.csr
echo "Done.";

cat config.ext | sed s/%%DOMAIN%%/$COMMON_NAME/g > /tmp/__v3.ext

echo "Generating the certificate...."
openssl x509 -req -in ${outdir}device.csr -CA ${outdir}rootCA.pem -CAkey ${outdir}rootCA.key -CAcreateserial -out ${outdir}device.crt -days $NUM_OF_DAYS -sha256 -extfile /tmp/__v3.ext
echo "Done"


while true; do
	read -p "Do would you like delete the root certificate? y[n]: " yn;
	case $yn in 
		[Yy]* ) 
			rm ./out/rootCA.key ./out/rootCA.pem;
			echo "The rootCA was delete.";
			break;
			;;
		[Nn]* ) 
			break;
			;;
		* ) 
			echo "Please answer yes or no.";
			;;
	esac
done

#rename the private and certificate file to the domain name
mv ${outdir}device.csr ${outdir}$DOMAIN.csr
mv ${outdir}device.key ${outdir}$DOMAIN.key
cp ${outdir}device.crt ${outdir}$DOMAIN.crt

#remove temp file
rm -f ${outdir}device.crt;
rm -f ${outdir}$DOMAIN.csr
rm -f ${outdir}rootCA.srl;
