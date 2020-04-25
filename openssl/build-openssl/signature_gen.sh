#!/bin/bash

home_dir=$(dirname $(find $(realpath ..) -name signature_gen.sh))
key_bit_length=2048

COUNTRY="FR"
STATE="FRANCE"
LOCALITY="vallauris"
ORGANIZATION_NAME="Elsys-design"
ORGANIZATIONAL_NAME="Advans Group"
COMMON_NAME="firmwareSigning"
subject="/C="$COUNTRY"/ST="$STATE"/L="$LOCALITY"/O="$ORGANIZATION_NAME"/OU="$ORGANIZATIONAL_NAME"/CN="$COMMON_NAME
key_pair_name="armald5keypair"
hash_file="hash_file"
available_cert=36500 
###############################################
# Generate private key + cert pair
###############################################
function generate_private_key_certificate {
    openssl req \
        -newkey rsa:${key_bit_length} \
        -nodes \
        -x509 \
        -days 36500 \
        -keyout ${home_dir}/${key_pair_name}.key.pem \
        -out ${home_dir}/${key_pair_name}.crt.pem \
        -subj "${subject}"
}
###############################################
# Sign file with private key, generate a <filename.sha256>
###############################################
function generate_signature {
    if [ -z $1 ]; then
        echo "Missing argument"
    else
        filename=$1
        echo "Generate signature for ${filename}..."
        # Hash file with sha256 algorithm
        # -binary to reduce size of file. When do not use -binary, it is in base64 and the size of hash file is over 256 bytes
        openssl dgst \
            -sha256 \
            -binary \
            -out $hash_file $filename 
        # Sign file
        openssl pkeyutl \
            -sign \
            -in ${hash_file} \
            -inkey ${home_dir}/${key_pair_name}.key.pem \
            -out $filename.bin
        # transfer to base 64
        openssl enc \
            -base64 \
            -in $filename.bin \
            -out $filename.sig 
        rm ${hash_file}
        rm $filename.bin
    fi
}

###############################################
# Check properties of certificate
###############################################
function check_properties_cert {
    openssl x509 -noout -in ${home_dir}/${key_pair_name}.crt.pem -issuer
    openssl x509 -noout -in ${home_dir}/${key_pair_name}.crt.pem -dates
}

##############################################
# Verify signature of file by using certificate (public key)
##############################################
function verify_signature {
    if [ -z $1 ]; then
        echo "Missing argument"
    else
        filename=$1
        echo "Verifying the signature of $filename..."
        # decode file signatured in base 64
        openssl enc \
            -d \
            -base64 \
            -in $filename.sig \
            -out $filename.bin
        # Hash file with sha256 algorithm
        openssl dgst \
            -sha256 \
            -binary \
            -out $hash_file $filename 
        # verify file signatured (compare hash code)
        openssl pkeyutl \
            -verify \
            -sigfile $filename.bin \
            -in $hash_file \
            -inkey <(openssl x509 -in $home_dir/$key_pair_name.crt.pem -pubkey -noout) \
            -pubin
        rm $filename.bin
        rm $hash_file
    fi
}

if [ "$1" == "generate_key_pair" ]; then
    generate_private_key_certificate
elif [ "$1" == "generate_signature" ]; then
    generate_signature $2
elif [ "$1" == check_properties_cert ]; then
    check_properties_cert
elif [ "$1" == "verify_signature" ]; then
    verify_signature $2
else
    echo -e "\n\e[1mUsage for Certs Generator: \e[22m\n"
    echo "        generate_key_pair                      # Generate private + public (certificate) key pair"
    echo "        generate_signature <filename>          # Sign file with private key, generate a <filename.sha256>"
    echo "        check_properties_cert                  # Check properties of certificate"
    echo "        verify_signature <filename>            # Verify signature of file by using public (certificate) key"
    exit 1
fi
