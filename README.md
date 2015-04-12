
# Build app's container
`docker build -t pooleo .`

# Run container on port 8080
`docker run -it -p 8080:80 pooleo`

# Example request including a success, and two failures
`curl -XPOST -d '{ "first_resource" : { "href" : "http://oneinchmile.com/tmp/rsp.json" }, "second_resource" : { "href" : "http://oneinchmile2.com" }, "third_resource" : { "href" : "http://oneinchmile.com/nothere" } }' -s http://localhost:8080/`
