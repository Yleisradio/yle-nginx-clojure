http_get() {
    local path="$1"
    curl --silent --fail --show-error \
        "http://nginx$path"
}
