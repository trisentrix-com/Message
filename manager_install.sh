#! /bin/bash

cd Message-manager-v2npm install
npm run build
cd ..
rm -rf manager/dist
cp -r message-manager-v2/dist manager/dist