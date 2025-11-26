FROM alpine:latest

# Install Lighttpd
RUN apk update && apk add lighttpd

# Create lighttpd configuration directly
RUN cat > /etc/lighttpd/lighttpd.conf <<'EOF'
server.document-root = "/var/www/localhost/htdocs"
server.port = 80

server.modules = (
    "mod_indexfile",
    "mod_access",
    "mod_alias",
    "mod_proxy"
)

index-file.names = ( "index.html" )

mimetype.assign = (
    ".html" => "text/html",
    ".css" => "text/css",
    ".js" => "application/javascript",
    ".json" => "application/json"
)

server.error-handler-404 = "/index.html"

# Proxy configuration for API
$HTTP["url"] =~ "^/api/" {
    proxy.server = ( "" =>
      (( "host" => "bv-api-service.bv-app.svc.cluster.local", "port" => 8000 ))
    )
    proxy.header = ( "map-urlpath" => ( "/api" => "" ) )
}
EOF

# Copy HTML file
COPY index.html /var/www/localhost/htdocs/index.html

# Create a simple health check file
RUN echo "OK" > /var/www/localhost/htdocs/health.html

# Create necessary directories and set permissions
RUN mkdir -p /var/log/lighttpd /var/run/lighttpd && \
    chown -R lighttpd:lighttpd /var/www/localhost /var/log/lighttpd /var/run/lighttpd

EXPOSE 80

USER lighttpd

CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]