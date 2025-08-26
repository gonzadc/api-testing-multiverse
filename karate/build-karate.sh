#!/bin/bash

# Nombre y tag de la imagen
IMAGE_NAME="karate-jre"
TAG="latest"

echo "==> Construyendo imagen $IMAGE_NAME:$TAG ..."
docker build -t $IMAGE_NAME:$TAG .

# Mostrar las imágenes creadas
docker images | grep $IMAGE_NAME
