# syntax=docker/dockerfile:1
FROM node:22.9-bookworm AS builder

WORKDIR /devel/
RUN apt-get update ; apt-get upgrade -y ; apt-get install -y python-is-python3 build-essential git
RUN git clone https://github.com/spacebarchat/server.git --depth 1
RUN cd server ; npm i ; npm run setup

FROM node:22.9-alpine3.19

EXPOSE 3001
WORKDIR /spacebar
RUN apk add --update git ; npm install pg --save
COPY --from=builder /devel/server/ . 
RUN adduser -D spacebar ; chown spacebar:spacebar -R .

USER spacebar

CMD ["npm", "run", "start"]
