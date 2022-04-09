##############################################
# Build system contracts
##############################################
FROM node:16.14 as contract-builder
RUN npm install -g npm@8.6.0
RUN npm install -g truffle@v5.5.7 --registry=https://registry.npm.taobao.org
ADD ./genesis /genesis
WORKDIR /genesis
RUN make install
RUN make compile

##############################################
# Create genesis and build bas
##############################################
FROM golang:1.16-alpine as bas-builder
RUN apk add --no-cache make gcc musl-dev linux-headers bash
ENV GOPROXY=https://goproxy.cn,direct
ADD . /bas
RUN rm -rf /bas/genesis
COPY --from=contract-builder /genesis /bas/genesis
WORKDIR /bas/genesis
RUN make create-genesis
WORKDIR /bas
RUN make geth

##############################################
#  Final image
##############################################
FROM alpine:latest
RUN apk add --no-cache ca-certificates curl jq tini bash
COPY --from=bas-builder  /bas/genesis/localnet.json /datadir/localnet.json
COPY --from=bas-builder  /bas/genesis/devnet.json /datadir/devnet.json
COPY --from=bas-builder  /bas/genesis/password.txt /datadir/password.txt
COPY --from=bas-builder  /bas/genesis/keystore /datadir/keystore
COPY --from=bas-builder  /bas/build/bin/geth /usr/local/bin
EXPOSE 8545 8546 8547 30303 30303/udp
ENTRYPOINT [ "geth" ]

