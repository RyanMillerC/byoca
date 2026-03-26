# BYOCA (Bring your own Certificate Authority)

Scripts to:

* Generate a self-signed CA root and root-signed intermediate cert
* Generate Certificate Signing Requests (CSR) and sign those with the intermediate cert

## Create CA (Root + Intermediate)

1. Update *config.cnf* (`C` and `O` values)
2. Run: `./scripts/create-ca.sh`

## Create Signed Leaf (End-User TLS Certificate)

1. Run: `./scripts/create-leaf.sh <domain> [subject-alternate-name-1 san-2 ...]`
    * **Example 1 (One SAN):** `./create_leaf.sh whatever.com`
    * **Example 2 (Multiple SANs):** `./create_leaf.sh whatever.com www.whatever.com other.whatever.com`
