## CONFIG LOCAL ENV
echo "[*] Config local environment..."
DOCKER='docker-compose exec vault'
export VAULT_ADDR=http://127.0.0.1:8200

## INIT VAULT
echo "[*] Init vault..."
${DOCKER} vault operator init -address=${VAULT_ADDR} > ./_data/keys.txt
export VAULT_TOKEN=$(grep 'Initial Root Token:' ./_data/keys.txt | awk '{print substr($NF, 1, length($NF)-1)}')

## UNSEAL VAULT
echo "[*] Unseal vault..."
${DOCKER} vault operator unseal -address=${VAULT_ADDR} $(grep 'Key 1:' ./_data/keys.txt | awk '{print $NF}')
${DOCKER} vault operator unseal -address=${VAULT_ADDR} $(grep 'Key 2:' ./_data/keys.txt | awk '{print $NF}')
${DOCKER} vault operator unseal -address=${VAULT_ADDR} $(grep 'Key 3:' ./_data/keys.txt | awk '{print $NF}')

## AUTH
echo "[*] Auth..."
${DOCKER} vault login -address=${VAULT_ADDR} ${VAULT_TOKEN}

## CREATE USER
echo "[*] Create user... Remember to change the defaults!!!"
${DOCKER} vault auth enable  -address=${VAULT_ADDR} userpass
${DOCKER} vault policy write -address=${VAULT_ADDR} admin ./config/admin.hcl
${DOCKER} vault write auth/userpass/users/webui password=webui policies=admin

## CREATE AppRole 
echo "[*] Create AppRole... Remember to change the defaults!!!"
${DOCKER} vault auth enable  -address=${VAULT_ADDR} approle
${DOCKER} vault write -address=${VAULT_ADDR} auth/approle/role/my-role \
    secret_id_ttl=10m \
    token_num_uses=10 \
    token_ttl=20m \
    token_max_ttl=30m \
    secret_id_num_uses=40

## CREATE BACKUP TOKEN
echo "[*] Create backup token..."
${DOCKER} vault token create -address=${VAULT_ADDR} -display-name="backup_token" | awk '/token/{i++}i==2' | awk '{print "backup_token: " $2}' >> ./_data/keys.txt

## MOUNTS
echo "[*] Creating new mount point..."
${DOCKER} vault vault secrets list -address=${VAULT_ADDR}
${DOCKER} vault vault secrets enable -address=${VAULT_ADDR} -path=assessment -description="Secrets used in the assessment" generic
${DOCKER} vault write  -address=${VAULT_ADDR} assessment/server1_ad value1=name value2=pwd

## READ/WRITE
# $ vault write -address=${VAULT_ADDR} secret/api-key value=12345678
# $ vault read -address=${VAULT_ADDR} secret/api-key