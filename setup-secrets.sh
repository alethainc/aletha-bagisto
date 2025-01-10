#!/bin/bash

# Secret name for the application
SECRET_NAME="aletha-bagisto/dev"

# Create JSON structure for secrets
cat << EOF > secrets.json
{
    "DB_CONNECTION": "mysql",
    "DB_HOST": "${DB_HOST}",
    "DB_PORT": "${DB_PORT}",
    "DB_DATABASE": "${DB_DATABASE}",
    "DB_USERNAME": "${DB_USERNAME}",
    "DB_PASSWORD": "${DB_PASSWORD}",
    "AWS_ACCESS_KEY_ID": "${AWS_ACCESS_KEY_ID}",
    "AWS_SECRET_ACCESS_KEY": "${AWS_SECRET_ACCESS_KEY}",
    "MAIL_USERNAME": "${MAIL_USERNAME}",
    "MAIL_PASSWORD": "${MAIL_PASSWORD}"
}
EOF

# Create or update the secret in AWS Secrets Manager
aws secretsmanager create-secret \
    --name "${SECRET_NAME}" \
    --description "Aletha Bagisto application secrets" \
    --secret-string file://secrets.json \
    || aws secretsmanager update-secret \
    --secret-id "${SECRET_NAME}" \
    --secret-string file://secrets.json

# Clean up the temporary file
rm secrets.json

echo "Secrets have been stored in AWS Secrets Manager under ${SECRET_NAME}" 