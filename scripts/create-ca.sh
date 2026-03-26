#!/bin/bash
#
# Creates a CA root and intermediate signing cert.
#

set -e

echo "Generating root CA key and certificate..."
mkdir -p pki/root
openssl genrsa -out pki/root/root.key 4096
# 3650 days = 10 years
openssl req -new -x509 -days 3650 \
  -key pki/root/root.key \
  -out pki/root/root.pem \
  -config root.cnf

echo "Generating intermediate key and CSR..."
mkdir pki/intermediate
openssl genrsa -out pki/intermediate/intermediate.key 4096
openssl req -new \
  -key pki/intermediate/intermediate.key \
  -out pki/intermediate/intermediate.csr \
  -config intermediate.cnf

echo "Signing intermediate certificate with root CA..."
# 1825 days = 5 years
openssl x509 -req -days 1825 \
  -in  pki/intermediate/intermediate.csr \
  -CA  pki/root/root.pem \
  -CAkey pki/root/root.key \
  -CAcreateserial \
  -out pki/intermediate/intermediate.pem \
  -extfile intermediate.cnf \
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
