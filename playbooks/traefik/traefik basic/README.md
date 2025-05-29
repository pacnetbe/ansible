# TRAEFIK basic
from https://docs.techdox.nz/traefik/ and video  https://www.youtube.com/watch?v=PzbdEZ4DQTg&t=55s

command: --configFile=/etc/traefik/traefik.yml > this needs most likely tweaking

# onfiguration File
At startup, Traefik searches for static configuration in a file named traefik.yml (or traefik.yaml or traefik.toml) in:

* /etc/traefik/
* $XDG_CONFIG_HOME/
* $HOME/.config/
* . (the working directory).

You can override this using the configFile argument.
> traefik --configFile=foo/bar/myconfigfile.yml