## Hydrate json objects
POST a json hash to the server's root
application will search recursively for the key `href`
it will make parallel calls out to all found href's
responses must be json hashes
POST will return original object hydrated with responses

# Build app's container (optional)
`docker build -t rranshous/pooleo .`

# Run container on port 8080
`docker run -it -p 8080:80 rranshous/pooleo`

# Example request including a success, and two failures
```
curl -XPOST -d '{ "first_resource" : { "href" : "http://oneinchmile.com/tmp/rsp.json" }, "second_resource" : { "href" : "http://oneinchmile2.com" }, "third_resource" : { "href" : "http://oneinchmile.com/nothere" } }' -s http://localhost:8080/`
```
