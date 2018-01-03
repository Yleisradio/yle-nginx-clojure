load helpers

@test "static page works" {
    run http_get "/"
    [ "$status" -eq 0 ]
    [ "$output" = "Hello World" ]
}
