#!/bin/bash

# Create directories
mkdir -p pretrain_data/chat
mkdir -p pretrain_data/images

# Download datasets
wget -P pretrain_data/chat/ https://huggingface.co/datasets/pi4/YugoLLaVA-CC3M-Pretrain-595K-HBS/resolve/main/cc3M-595k-HBS.json
wget -P pretrain_data/images/ https://huggingface.co/datasets/liuhaotian/LLaVA-CC3M-Pretrain-595K/resolve/main/images.zip?download=true

# Unzip datasets
unzip pretrain_data/images/images.zip -d pretrain_data/images/

# Remove zip files
rm pretrain_data/images/images.zip
