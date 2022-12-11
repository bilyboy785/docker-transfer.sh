# transfersh 1.4.0 on Golang 1.19-alpine3.17
# Latest

FROM golang:1.19-alpine3.17 as build

# Necessary to run 'go get' and to compile the linked binary
RUN apk add git musl-dev

ADD . /go/src/github.com/dutchcoders/transfer.sh

WORKDIR /go/src/github.com/dutchcoders/transfer.sh

ENV GO111MODULE=on

# build & install server
RUN CGO_ENABLED=0 go build -tags netgo -ldflags "-X github.com/dutchcoders/transfer.sh/cmd.Version=$(git describe --tags) -a -s -w -extldflags '-static'" -o /go/bin/transfersh

ARG PUID=5000 \
    PGID=5000 \
    RUNAS

RUN mkdir -p /tmp/useradd /tmp/empty && \
    if [ ! -z "$RUNAS" ]; then \
    echo "${RUNAS}:x:${PUID}:${PGID}::/nonexistent:/sbin/nologin" >> /tmp/useradd/passwd && \
    echo "${RUNAS}:!:::::::" >> /tmp/useradd/shadow && \
    echo "${RUNAS}:x:${PGID}:" >> /tmp/useradd/group && \
    echo "${RUNAS}:!::" >> /tmp/useradd/groupshadow; else touch /tmp/useradd/unused; fi

FROM scratch AS final
LABEL maintainer="Martin Bouillaud <contact@bouillaudmartin.fr"
ARG RUNAS

COPY --from=build /tmp/empty /tmp
COPY --from=build /tmp/useradd/* /etc/
COPY --from=build --chown=${RUNAS}  /go/bin/transfersh /go/bin/transfersh
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

USER ${RUNAS}

ENTRYPOINT ["/go/bin/transfersh", "--listener", ":8080"]

EXPOSE 8080
