# clj.sh

Run Clojure and Babashka functions without any prior installation.

This code is deployed as a service to [clj.sh](https://clj.sh) for free public use.

## Usage

```
# Call a main function
$ curl -fsSL clj.sh/io.github.babashka/neil | sh

# Pass arguments
$ curl -fsSL clj.sh/io.github.babashka/neil | sh -s -- --version

# If you want, you can download the script first to verify its content
$ curl -fsSL clj.sh/io.github.babashka/neil > neil
$ chmod +x neil
$ ./neil
```

## Self-Hosting

This repo includes a `Dockerfile` and `docker-compose.yaml` to make it easy to deploy on your own. The public clj.sh deployments happen manually through the `bin/deploy` script, which is a thin wrapper around Docker and SSH.

That said, this is a typical Ring server and Docker isn't required, so you can deploy this as you would any other Clojure web app.

## Contributing

If you'd like to contribute to clj.sh, you're welcome to create [issues for ideas, feature requests, and bug reports](https://github.com/rads/clj.sh/issues).

## License

Copyright © 2024 Radford Smith

clj.sh is distributed under the [MIT License](LICENSE).
