#!/bin/bash

home_dir=$(dirname $(find $(realpath ..) -name image_encryption.sh))
key_bit_length=2048

COUNTRY="FR"
STATE="FRANCE"
LOCALITY="vallauris"
ORGANIZATION_NAME="Elsys-design"
ORGANIZATIONAL_NAME="Advans Group"
COMMON_NAME="firmwareSigning"
subject="/C="$COUNTRY"/ST="$STATE"/L="$LOCALITY"/O="$ORGANIZATION_NAME"/OU="$ORGANIZATIONAL_NAME"/CN="$COMMON_NAME
key_pair_prefix="armald5keypair"
password_file_prefix="password"
hash_file="hash_file"
available_cert=36500 
algorithm_enc="aes-256-cbc"
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
# Encrypt file with password file, then encrypt password file with public key
# ${filename} -> ${filename}.enc + ${filename}.enc.key
###############################################
function encrypt_file {
    if [ -z $1 ] ; then
        echo "Argument missing"
    else
        filename=$1
        # Generate randomly password
        openssl rand \
            -base64 48 \
            > ${password_file_prefix}.key.txt
        # Encrypt file with random password
        openssl enc \
            -${algorithm_enc} \
            -base64 \
            -salt \
            -pbkdf2 \
            -iter 1000 \
            -in ${filename} \
            -out ${filename}.enc \
            -kfile ${password_file_prefix}.key.txt
        # Encypt password with certificate
        openssl pkeyutl \
            -encrypt \
            -in ${password_file_prefix}.key.txt \
            -inkey <(openssl x509 -in ${home_dir}/$key_pair_prefix.crt.pem -pubkey -noout) \
            -pubin \
            -out ${password_file_prefix}.key.bin
        # Change to base64
        openssl enc \
            -base64 \
            -in ${password_file_prefix}.key.bin \
            -out ${password_file_prefix}.key.enc
        rm ${password_file_prefix}.key.txt
        rm ${password_file_prefix}.key.bin
    fi
}

###############################################
# Decrypt password file with private key, then decrypt file with password file
# ${filename}.enc + ${filename}.enc.key -> ${filename}
###############################################
function decrypt_file {
    if [ -z $1 ] ; then
        echo "Argument missing"
    else
        filename=$1
        file_prefix=${filename%.*}
        echo ${file_prefix}
        openssl enc \
            -base64 \
            -d \
            -in ${password_file_prefix}.key.enc \
            -out ${password_file_prefix}.key.bin
        openssl pkeyutl \
            -decrypt \
            -in ${password_file_prefix}.key.bin \
            -inkey ${home_dir}/$key_pair_prefix.key.pem \
            -out ${password_file_prefix}.key.txt
        openssl enc \
            -${algorithm_enc} \
            -d \
            -iter 1000 \
            -pbkdf2 \
            -base64 \
            -in ${file_prefix}.enc \
            -out ${file_prefix} \
            -pass file:${password_file_prefix}.key.txt
        rm ${password_file_prefix}.key.txt
        rm ${password_file_prefix}.key.bin
    fi
}

###############################################
# Check properties of certificate
###############################################
function check_properties_cert {
    openssl x509 -noout -in ${home_dir}/${key_pair_name}.crt.pem -issuer
    openssl x509 -noout -in ${home_dir}/${key_pair_name}.crt.pem -dates
}

if [ "$1" == "generate_key_pair" ]; then
    generate_private_key_certificate
elif [ "$1" == "encrypt_file" ]; then
    encrypt_file $2
elif [ "$1" == check_properties_cert ]; then
    check_properties_cert
elif [ "$1" == "decrypt_file" ]; then
    decrypt_file $2
else
    echo -e "\n\e[1mUsage for Certs Generator: \e[22m\n"
    echo "        generate_key_pair                      # Generate private + public (certificate) key pair"
    echo "        encrypt_file <filename>                # encrypt file  with random key, and encrypt random password with certificate"
    echo "        check_properties_cert                  # Check properties of certificate"
    echo "        decrypt_file <filename>                # decrypt random password with private key and decrypt file  with random key"
    exit 1
fi