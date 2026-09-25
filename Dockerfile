FROM golang:1.27-alpine AS build

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app ./cmd/api

FROM gcr.io/distroless/static-debian12:nonroot

USER nonroot:nonroot

COPY --from=build /app /app

EXPOSE 8080

ENTRYPOINT ["/app"]
