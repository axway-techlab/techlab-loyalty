FROM stoplight/prism:4
COPY "api-spec.yaml" /tmp/mock.yaml
EXPOSE 4010
CMD ["mock", "-d", "-h", "0.0.0.0", "/tmp/mock.yaml"]