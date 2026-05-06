FROM node:24-alpine AS builder

RUN apk update && \
    apk add --no-cache git ffmpeg wget curl bash openssl dos2unix

LABEL version="2.3.7" description="Message API to control whatsapp features through http requests." 
LABEL maintainer="message" git="https://github.com/message/message"
LABEL contact="support@message-api.com"

WORKDIR /message

COPY ./package*.json ./
COPY ./tsconfig.json ./
COPY ./tsup.config.ts ./

RUN npm ci --silent

COPY ./src ./src
COPY ./public ./public
COPY ./prisma ./prisma
COPY ./manager ./manager
COPY ./env.example ./.env
COPY ./runWithProvider.js ./

COPY ./Docker ./Docker

RUN chmod +x ./Docker/scripts/* && dos2unix ./Docker/scripts/*

RUN ./Docker/scripts/generate_database.sh

RUN npm run build

FROM node:24-alpine AS final

RUN apk update && \
    apk add tzdata ffmpeg bash openssl

ENV TZ=America/Sao_Paulo
ENV DOCKER_ENV=true

WORKDIR /message

COPY --from=builder /message/package.json ./package.json
COPY --from=builder /message/package-lock.json ./package-lock.json

COPY --from=builder /message/node_modules ./node_modules
COPY --from=builder /message/dist ./dist
COPY --from=builder /message/prisma ./prisma
COPY --from=builder /message/manager ./manager
COPY --from=builder /message/public ./public
COPY --from=builder /message/.env ./.env
COPY --from=builder /message/Docker ./Docker
COPY --from=builder /message/runWithProvider.js ./runWithProvider.js
COPY --from=builder /message/tsup.config.ts ./tsup.config.ts

ENV DOCKER_ENV=true

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "-c", ". ./Docker/scripts/deploy_database.sh && npm run start:prod" ]
