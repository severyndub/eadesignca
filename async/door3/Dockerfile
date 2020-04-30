FROM golang:latest AS build
WORKDIR /src/
COPY . /src/
RUN CGO_ENABLED=0 go build -o /bin/newsfetcher

FROM scratch
COPY --from=build /bin/newsfetcher /bin/newsfetcher
ENTRYPOINT ["/bin/newsfetcher"]
