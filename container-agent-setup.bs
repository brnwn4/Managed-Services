az container create \
    --resource-group rg-buildagent \
    --name azdobuildagent \
    --image <Dockerhub_account>/terraform:3233 \
    --restart-policy OnFailure \
    --environment-variables 'AZP_AGENT_NAME'='agent01' 'AZP_POOL'='docker-build-agents' 'AZP_URL'='<AZDO_LINK_WAS_CT.CLOUD_before>' 'AZP_TOKEN'='<AZDO_PAT_TOKEN>' \
    --subnet <SUBNET_RESOURCE_ID>
