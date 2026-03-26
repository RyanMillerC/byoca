#!/bin/bash
#
# create-leaf.sh <domain> [subject-alternate-name-1 san-2 ...]
#
# Examples:
#   ./create-leaf.sh whatever.com
#   ./create-leaf.sh whatever.com www.whatever.com other.whatever.com 
#

set -e

CN="${1:-}"
shift || true
EXTRA_SANS=("$@")

if [[ -z "$CN" ]]; then
  echo "Usage: $0 <domain> [subject-alternate-name-1 san-2 ...]" >&2
  exit 1
fi

OUTDIR="./pki/$CN"
mkdir -p "$OUTDIR"

# Format list of subject alt names
SAN_STRING="DNS:${CN}"
for s in "${EXTRA_SANS[@]}"; do
  SAN_STRING="${SAN_STRING}, DNS:${s}"
done

echo "Generating $CN key and CSR..."
cat > "$OUTDIR/$CN.cnf" << EOF
[req]
prompt             = no
distinguished_name = dn

[dn]
$(cat config.cnf)
CN = ${CN}

[ext]
basicConstraints       = critical, CA:FALSE
keyUsage               = critical, digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth, clientAuth
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always
subjectAltName         = ${SAN_STRING}
EOF
openssl genrsa -out "$OUTDIR/$CN.key" 2048
openssl req -new \
  -key    "$OUTDIR/$CN.key" \
  -out    "$OUTDIR/$CN.csr" \
  -config "$OUTDIR/$CN.cnf"

echo "Signing $CN with intermediate CA..."
openssl x509 -req -days 365 \
  -in      "$OUTDIR/$CN.csr" \
  -CA      pki/intermediate/intermediate.pem \
  -CAkey   pki/intermediate/intermediate.key \
  -CAcreateserial \
  -out     "$OUTDIR/$CN.pem" \
  -extfile "$OUTDIR/$CN.cnf" \
  -extensions ext
# Create full chain cert file
cat "$OUTDIR/$CN.pem" \
    pki/intermediate/intermediate.pem \
    pki/root/root.pem \
    > "$OUTDIR/$CN.chain.pem"

echo "Verifying certificate..."
openssl verify -CAfile pki/root/root.pem -untrusted pki/intermediate/intermediate.pem "$OUTDIR/$CN.pem"

echo "Done. Files written to ./pki"
echo
echo "$CN Certificate: $OUTDIR/$CN.pem"
openssl x509 -noout -subject -issuer -dates -fingerprint -in "$OUTDIR/$CN.pem"
echo
echo "Cert       : $OUTDIR/$CN.pem"
echo "Full chain : $OUTDIR/$CN.chain.pem"
echo "Key        : $OUTDIR/$CN.key"
