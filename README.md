# wireline-openfaas-node8-container

# Example

```
docker build -t localhost:5000/nodejs .
docker push localhost:5000/nodejs
```

# TODO

* We need to pick up more info from `service.yml` and `wireline.yml` to setup the routes and parameters.

* Right now the container is selected automatically during deployment by the literal value of `${service.platform}`--hence the simple tag of `nodejs` above.  We may need to come up with something more unique (or at least map to something ore unique).
