FROM alpine:edge
MAINTAINER Mark Riedesel <mark@klowner.com>

ENV GITLAB_MIRROR_ASSETS=/assets \
	GITLAB_MIRROR_USER=git \
	GITLAB_MIRROR_HOME=/config \
	GITLAB_MIRROR_INSTALL_DIR=/opt/gitlab-mirror \
	GITLAB_MIRROR_REPO_DIR=/data

RUN apk update \
	&& apk add bash git gettext git-svn bzr mercurial python py-setuptools openssl \
		sudo perl-git openssh-client \
	&& rm -rf /var/cache/apk/*

# git-bzr-helper
RUN wget https://raw.github.com/felipec/git-remote-bzr/master/git-remote-bzr -O /usr/local/bin/git-remote-bzr \
	&& chmod 755 /usr/local/bin/git-remote-bzr

# git-hg-helper
RUN wget https://raw.github.com/felipec/git-remote-hg/master/git-remote-hg -O /usr/local/bin/git-remote-hg \
	&& chmod 755 /usr/local/bin/git-remote-hg

# python-requests
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/kennethreitz/requests.git \
	&& cd requests \
	&& python setup.py install \
	&& cd .. && rm -rf requests

# python-gitlab3
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/alexvh/python-gitlab3.git \
	&& cd python-gitlab3 \
	&& python setup.py install \
	&& cd .. && rm -rf python-gitlab3

WORKDIR /
RUN git clone --depth 1 https://github.com/samrocketman/gitlab-mirrors.git ${GITLAB_MIRROR_INSTALL_DIR}

COPY assets ${GITLAB_MIRROR_ASSETS}
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

VOLUME ["${GITLAB_MIRROR_REPO_DIR}", "${GITLAB_MIRROR_HOME}"]
WORKDIR ${GITLAB_MIRROR_HOME}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["help"]
