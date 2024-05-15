# Docker Image for micanto
This is a small docker image based on the official php docker image. 
It installs the latest micanto php/react app in the container.

## How to use
1. Clone this repository to your server/pc
2. Create the needed folders for your local assets and to persist them. These are:
   * `music` - the folder with your music files
   * `img` - a folder where micanto will save the covers from artists, albums, playlists and users
   * `mariadb` - your database data will be stored outside of docker to persist
   * `search_index` - the sqlite files with your search index
4. Change the username/password data in the `docker-compose.yaml` for your needs
4. Let docker compose your application: `docker compose up -d`

That's all!
Happy listening to your music

This image is for using behind a reverse proxy. You can change the posts in docker-compose.yaml to 443 if you want to use it directly with ssl. But then you have to add the certificates by yourself.
