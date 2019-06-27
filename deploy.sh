#! /bin/bash


#remove old key and generate new one
sudo rm -f key.pem public.pem public_header.pem 

sudo openssl genrsa -out key.pem 2048 && openssl rsa -in key.pem -outform PEM -pubout -out public_header.pem

sed -e '9d;1d' public_header.pem > public.pem
