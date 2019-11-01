# About this Repo

This is the Git repo of the official Docker image for [nginx](https://registry.hub.docker.com/_/nginx/). See the
Hub page for the full readme on how to use the Docker image and for information
regarding contributing and issues.

The full readme is generated over in [docker-library/docs](https://github.com/docker-library/docs),
specifically in [docker-library/docs/nginx](https://github.com/docker-library/docs/tree/master/nginx).

## CTDS Customization

```
git remote add nginx https://github.com/nginxinc/docker-nginx.git

git rebase cdis nginx/whatever-version-you-want

fix/customize as necessary
```

## CTDS Additions

Add more_headers module to mainline/alpine-perl
