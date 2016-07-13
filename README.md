[![Docker Repository on Quay](https://quay.io/repository/klowner/gitlab-mirrors/status "Docker Repository on Quay")](https://quay.io/repository/klowner/gitlab-mirrors)

# gitlab-mirrors for Docker

This is [samrocketman/gitlab-mirrors](https://github.com/samrocketman/gitlab-mirrors) packaged inside a Docker container
based on Alpine Linux.

## Quick-start
Automated builds are available from [quay.io](https://quay.io)
```bash
docker pull quay.io/klowner/gitlab-mirrors:latest
```
The `/config` volume serves as the `$HOME` for the container's user. A few files are required for this container to work.
- `/config/.ssh/config`: any custom ssh configuration you need when connecting to the GitLab server. (See the ssh/config example further down the page).
- `/config/.ssh/id_rsa`: an SSH private key associated with the GitLab user that will be pushing mirrors
- `/config/private_token`: The private API token for the GitLab user, this can be obtained in your GitLab user profile in the web UI.
- `/config/.bashrc`: *optional* add any pre-init for commands, such as starting `ssh-agent` or adding ssh keys.

> You can initialize the `/config` volume by running the container with the `config` command.

Test your configuration to verify that SSH keys and SSH configuration is correct
```bash
docker run --rm -it \
  -v ${PWD}/config:/config \
  quay.io/klowner/gitlab-mirrors:latest \
  run ssh git.example.com
```

Add a repo to mirror (this example shows mirroring the pcre2 library)
```bash
docker run --rm -it \
  -v "${PWD}/config:/config" \
  -v "${PWD}/mirrors:/data/mirrors" \
  -e GITLAB_MIRROR_GITLAB_USER=mark \
  -e GITLAB_MIRROR_GITLAB_NAMESPACE=Mirrors \
  -e GITLAB_MIRROR_GITLAB_URL=http://git.example.com \
  -e GITLAB_MIRROR_SVN_OPTIONS='-r500:HEAD -T code/trunk/ -t code/tags/' \
  quay.io/klowner/gitlab-mirrors:latest \
  add --svn --project-name pcre2 --mirror svn://vcs.exim.org/pcre2
```
If all goes well, this will mirror `svn://vcs.exim.org/pcre2` to `http://git.example.com/Mirrors/pcre2`.

I recommend making a short script such as this for running updates, etc. This example also exposes ssh-agent to the container for convenience.
```bash
# gitlab-mirror.sh
docker run --rm -i \
  -v $(dirname $SSH_AUTH_SOCK):$(dirname $SSH_AUTH_SOCK) \
  -v "${PWD}/config:/config" \
  -v "${PWD}/mirrors:/data/Mirrors" \
  -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK \
  -e GITLAB_MIRROR_UID=$(id -u) \
  -e GITLAB_MIRROR_GITLAB_USER=mark \
  -e GITLAB_MIRROR_GITLAB_NAMESPACE=Mirrors \
  -e GITLAB_MIRROR_GITLAB_URL=http://git.klowner.com \
  quay.io/klowner/gitlab-mirrors:latest ${@:1}
```
Then you can
```bash
./gitlab-mirror.sh update
```

## Configuration Options
#### Required parameters
- **GITLAB_MIRROR_GITLAB_NAMESPACE:** GitLab namespace that mirrors will be pushed to (default: `'Mirrors'`)
- **GITLAB_MIRROR_GITLAB_USER:** GitLab username to use for pushing to gitlab (default: `git`)
- **GITLAB_MIRROR_GITLAB_URL:** http(s) URL of the GitLab server you'll be pushing mirrors to

#### Optional parameters
- **GITLAB_MIRROR_USER:** the system user that gitlab-mirrors will run as inside the container (default: `git`)
- **GITLAB_MIRROR_UID:** the userid to use for the system user above (default: `1000`)
- **GITLAB_MIRROR_HOME:** location of system user's home volume, this contains the gitlab `private_token` and `~/.ssh` (default: `/config`)
- **GITLAB_MIRROR_INSTALL_DIR:** location of [gitlab-mirrors](https://github.com/samrocketman/gitlab-mirrors/) (default: `/opt/gitlab-mirrors`)
- **GITLAB_MIRROR_REPO_DIR:** location of repositories volume, this should be persistent so you can run `update` later (default: `/data`)
- **GITLAB_MIRROR_COLORS:** enable color output (default: true)
- **GITLAB_MIRROR_SVN_OPTIONS:** additional parameters passed to `git-svn` (default: `'-s'`)
- **GITLAB_MIRROR_NO_CREATE_SET:** Force gitlab-mirrors to not create the gitlab remote so a remote URL must be provided. (superceded by no_remote_set)
- **GITLAB_MIRROR_NO_REMOTE_SET:** Force gitlab-mirrors to only allow local remotes only.
- **GITLAB_MIRROR_FORCE_UPDATE:** Enable force fetching and pushing. Will overwrite references if upstream force pushed. Applies to git projects only.
- **GITLAB_MIRROR_PRUNE_MIRRORS:** If a branch is deleted upstream then only that change will propagate into your GitLab mirror. Applies to git projects only (default: `false`)
- **GITLAB_MIRROR_HTTP_REMOTE:** push to GitLab over http? Otherwise will push projects via SSH (default: false)

#### These options affect the configuration options for new mirror repositories
- **GITLAB_MIRROR_NEW_ISSUES_ENABLED:** (default: false)
- **GITLAB_MIRROR_NEW_WALL_ENABLED:** (default: false)
- **GITLAB_MIRROR_NEW_WIKI_ENABLED:** (default: false)
- **GITLAB_MIRROR_NEW_SNIPPETS_ENABLED:** (default: false)
- **GITLAB_MIRROR_NEW_MERGE_REQUESTS_ENABLED:** (default: false)
- **GITLAB_MIRROR_NEW_PUBLIC:** (default: false)


## Example configuration using docker-compose
Here's an example `docker-compose.yml` to simplify interacting with *docker-gitlab-mirrors*.
```
version: '2'

services:
  gitlab-mirrors:
    image: quay.io/klowner/gitlab-mirrors:latest
    volumes:
      - /srv/gitlab-mirrors/config:/config
      - /srv/gitlab-mirrors/data:/data
    environment:
      - GITLAB_MIRROR_UID=1000
      - GITLAB_MIRROR_GITLAB_USER=mark
      - GITLAB_MIRROR_GITLAB_NAMESPACE=mirrors
      - GITLAB_MIRROR_GITLAB_URL=http://gitlab
    external_links:
      - gitlab:gitlab
    networks:
      - gitlab_front

networks:
  gitlab_front:
    external:
      name: gitlab_front
```
- My `/config` and `/data` volumes are stored on the docker host's `/srv/gitlab-mirrors` directory.
- The `external_links` specifies the name of my running `gitlab` container, this matches the `GITLAB_MIRROR_GITLAB_URL=http://gitlab`.
- `gitlab_front` is a named Docker network, this is added so the `docker-gitlab-mirrors` container can connect to the `gitlab` container.

Using the above example, you can run the container via `docker-compose` without the necessity to provide configuration options repeatedly.

From the directory containing your `docker-compose.yml`
```
# docker-compose run --rm gitlab-mirrors
Available options:
 mirrors           - Update all mirrors
 add               - Add a new mirror
 delete            - Delete a mirror
 ls                - List registered mirrors
 update <project>  - Update a single mirror
 config            - Populate the /config volume with ~/.ssh and other things
 run <command>     - Run an arbitrary command inside the container
```
Run some commands!

## Example .ssh/config
After running `config` your `/config` volume will be populated with some starter files. You can provide additional configuration settings by customizing the `/config/.ssh/config`. Here's something similar to what I use, you should be able to adapt it to your needs.
```
Host gitlab.example.com
  Hostname gitlab
  User git
  ForwardAgent yes
  StrictHostKeyChecking no
  IdentityFile ~/.ssh/id_rsa_for_mirror_user
```
If everything is set up properly, you can use the container's `run` command to try connecting to your gitlab server via ssh. eg.
`docker-compose run --rm gitlab-mirrors run ssh gitlab.example.com`
If all goes well, you should get a `"Welcome to GitLab, <your user>!"` repsonse.
