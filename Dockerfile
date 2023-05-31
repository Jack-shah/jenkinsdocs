FROM node:14.20.0-slim

RUN npm install -g @angular/cli &&\
    apt-get install git -y
    
    
