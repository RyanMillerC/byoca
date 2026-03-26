#!/bin/bash
#
# Creates a CA root and intermediate signing cert.
#

set -e

CA_NAME=$(grep '^O\s*=' config.cnf | sed 's/^O\s*=\s*//')

echo "Generating root CA key and certificate..."
mkdir -p pki/root
cat > pki/root/root.cnf << EOF
[req]
prompt             = no
distinguished_name = dn
x509_extensions    = ext
 
$(cat config.cnf)
CN = $CA_NAME Root
 
[ext]
basicConstraints = critical, CA:TRUE
keyUsage         = critical, keyCertSign, cRLSign
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always
EOF
openssl genrsa -out pki/root/root.key 4096
# 3650 days = 10 years
openssl req -new -x509 -days 3650 \
  -key pki/root/root.key \
  -out pki/root/root.pem \
  -config pki/root/root.cnf

echo "Generating intermediate key and CSR..."
mkdir pki/intermediate
cat > pki/intermediate/intermediate.cnf << EOF
[req]
prompt             = no
distinguished_name = dn
 
[dn]
$(cat config.cnf)
CN = $CA_NAME Intermediate
 
[ext]
basicConstraints = critical, CA:TRUE, pathlen:0
keyUsage         = critical, keyCertSign, cRLSign
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always
EOF
openssl genrsa -out pki/intermediate/intermediate.key 4096
openssl req -new \
  -key pki/intermediate/intermediate.key \
  -out pki/intermediate/intermediate.csr \
  -config pki/intermediate/intermediate.cnf

echo "Signing intermediate certificate with root CA..."
# 1825 days = 5 years
openssl x509 -req -days 1825 \
  -in  pki/intermediate/intermediate.csr \
  -CA  pki/root/root.pem \
  -CAkey pki/root/root.key \
  -CAcreateserial \
  -out pki/intermediate/intermediate.pem \
  -extfile pki/intermediate/intermediate.cnf \
  -extensions ext
# Create full chain cert file
cat pki/intermediate/intermediate.pem pki/root/root.pem > pki/intermediate/intermediate.chain.pem

echo "Creating CA bundle with root and intermediate..."
cat > pki/ca-bundle.pem << EOF
# Root CA
$(cat pki/root/root.pem)

# Intermediate CA
$(cat pki/intermediate/intermediate.pem)
EOF

echo "Verifying certificates..."
openssl verify -CAfile pki/root/root.pem pki/intermediate/intermediate.pem

echo "Done. Files written to ./pki"
echo
echo "Root Certificate: ./pki/root/root.pem"
openssl x509 -noout -subject -issuer -dates -fingerprint -in pki/root/root.pem
echo
echo "Intermediate Certificate: ./pki/intermediate/intermediate.pem"
openssl x509 -noout -subject -issuer -dates -fingerprint -in pki/intermediate/intermediate.pem
