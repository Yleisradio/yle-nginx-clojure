# Deprecated

Yle moved to pure NGINX with extra logic done with NJS. This version is no longer maintained.

# Yle Nginx with Nginx-Clojure

[![Build Status](https://travis-ci.org/Yleisradio/yle-nginx-clojure.svg?branch=master)](https://travis-ci.org/Yleisradio/yle-nginx-clojure)

Scripts for building a Docker image of [nginx](https://nginx.org/) with the [nginx-clojure](https://nginx-clojure.github.io/) module. This is made for [Yle](https://yle.fi/), but should be generic.

Docker images built by Yle can be found in Docker Hub as [yleisradio/yle-nginx-clojure](https://hub.docker.com/r/yleisradio/yle-nginx-clojure/).

## Requirements

* [Docker](https://docs.docker.com/) and [Docker compose](https://docs.docker.com/compose/)
* Basic developer tooling, like Make and curl

## Building

* Set `NGINX_VERSION` and `NGINX_CLOJURE_VERSION` variables in the `VERSIONS` file.
* Run `make shasums` to update SHA sums and add them to repository.
* Run `make test` to build and test the `yle-nginx-clojure` image.

### Caching

To disable Docker's caching set environment variable `DOCKER_BUILD_OPTIONS`:

```sh
DOCKER_BUILD_OPTIONS="--no-cache --force-rm" make
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Yleisradio/yle-nginx-clojure. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
