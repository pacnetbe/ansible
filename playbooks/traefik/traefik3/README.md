this is based on Jim's garage traefik3 video
= https://www.youtube.com/watch?v=CmUzMi5QLzI



comments for .env
to create the token
on the host: echo $(htpasswd -nB <replace with the user name>) | sed -e s/\\$/\\$\\$/g
> type password
> copy the result in .env

# Network creation:
    - option 1: run once the container with "external: true" commented then uncomment it
    - option 2: create network before running container with "docker network <name of network>" and check with "docker network list"
    