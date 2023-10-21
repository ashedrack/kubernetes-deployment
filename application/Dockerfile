# checkov:skip=CKV_DOCKER_7: "Ensure the base image uses a non latest version tag"

FROM golang:1.21 as build

WORKDIR /go/src/app
COPY . .

RUN go mod download
RUN go vet -v
RUN go test -v

RUN CGO_ENABLED=0 go build -o /go/bin/app


FROM gcr.io/distroless/static-debian11
# Non-root user
USER nobody

COPY --from=build /go/bin/app /

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD [ "wget", "-q", "-O", "-", "http://localhost:5000/health" ] || exit 1
EXPOSE 5000

CMD ["/app"]
