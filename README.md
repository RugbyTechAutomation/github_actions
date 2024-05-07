# Useful Commands

## Create Image

docker buildx build --tag "ansible.docker" --file ".\ansible.ubuntu.dockerfile" .

## Upload Image

az login
az acr login --name acransadvuks01 #.azurecr.io

### docker login acransadvuks01.azurecr.io

## Create an alias of the image

docker tag ansible.docker acransadvuks01.azurecr.io/ansible/ubuntu

## Push the image to your registry

docker push acransadvuks01.azurecr.io/ansible/ubuntu
