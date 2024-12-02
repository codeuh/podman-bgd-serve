#!/bin/bash

configFilePath="/etc/nginx/conf.d/default.conf"
oldPort=$1  
newPort=$2  

cp $configFilePath ${configFilePath}.backup

sed -i "s/proxy_pass http:\/\/host\.containers\.internal:$oldPort;/proxy_pass http:\/\/host\.containers\.internal:$newPort;/g" $configFilePath

nginx -t

if [ $? -eq 0 ]; then
    nginx -s reload
    echo "Nginx configuration updated and reloaded successfully."
else
    echo "Nginx configuration test failed. Reverting to the original configuration."
    cp ${configFilePath}.backup $configFilePath
fi