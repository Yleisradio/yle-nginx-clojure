load helpers

@test "clojure works" {
    run http_get "/clojure"
    [ "$status" -eq 0 ]
    [ "$output" = "Lua FTW!" ]
}

@test "set variable in clojure" {
    run http_get "/clojure-var"
    [ "$status" -eq 0 ]
    [ "$output" = "Hello worm" ]
}
