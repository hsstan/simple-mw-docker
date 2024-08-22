# simple-mw-docker

this repo offers a straight forward solution to deploy a Mediawiki within only one Docker container

**Note**: this repo is a clone of [https://github.com/offspot/mediawiki-docker](https://github.com/offspot/mediawiki-docker), that is stuck at Medaiwiki 1.36

[![CodeFactor](https://www.codefactor.io/repository/github/hsstan/simple-mw-docker/badge/main)](https://www.codefactor.io/repository/github/hsstan/simple-mw-docker/overview/main)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Run
---

To create your Docker container:

```bash
sudo docker pull -a ghcr.io/hsstan/mediawiki

sudo docker run -p 8080:80 \
  -v <YOUR_CUSTOM_DATA_DIRECTORY>:/var/www/data -it ghcr.io/hsstan/mediawiki
```

Connect to your Docker container with your browser at
http://localhost:8080/

User credentials
----------------

* **user**: admin
* **password**: mediawikipass

**Note**: you can temporarily restrict access to your mediawiki by setting the `HTPASSWORD` environment variable.
This will not affect your wiki's configuration but accessing it will require to log-in with their browser
using Username `user` and the passed password.

Customise
---------

The `data` directory contains the database, images, file config and
images. Everything which makes your Mediawiki instance unique. It is
initialized when the container is created if needed files are not
present (LocalSettings.custom.php and the MySQLite file).

You can customise the Mediawiki by editing your
`config/LocalSettings.custom.php`. If you want to know more, have a
look to this documentation:
https://www.mediawiki.org/wiki/Manual:LocalSettings.php

Backup
------

All your data are available in your `<YOUR_CUSTOM_DATA_DIRECTORY>`
data directory.
