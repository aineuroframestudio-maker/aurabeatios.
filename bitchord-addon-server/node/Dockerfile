FROM node:20-alpine

WORKDIR /app

COPY package.json bitchord-addon-auth.mjs server.mjs ./

ENV PORT=8080
ENV BITCHORD_HOSTS="bitchord.confih.tech"
ENV BITCHORD_AUTH_MODE="enforce"

EXPOSE 8080

CMD ["node", "server.mjs"]
