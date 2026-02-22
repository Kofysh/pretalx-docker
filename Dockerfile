FROM python:3.14-trixie

ENV LC_ALL=C.UTF-8

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        gettext \
        git \
        libmariadb-dev \
        libmemcached-dev \
        libpq-dev \
        locales \
        nodejs \
        npm \
        sudo \
        supervisor \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    dpkg-reconfigure locales; \
    locale-gen C.UTF-8; \
    /usr/sbin/update-locale LANG=C.UTF-8; \
    mkdir -p /etc/pretalx /data /public; \
    groupadd -g 999 pretalxuser; \
    useradd -r -u 999 -g pretalxuser -d /pretalx -m -s /bin/bash pretalxuser; \
    echo 'pretalxuser ALL=(ALL) NOPASSWD:SETENV: /usr/bin/supervisord' >> /etc/sudoers

COPY --chown=pretalxuser:pretalxuser pretalx/pyproject.toml /pretalx/pyproject.toml
COPY --chown=pretalxuser:pretalxuser pretalx/src /pretalx/src
COPY --chown=root:root deployment/docker/pretalx.bash /usr/local/bin/pretalx
COPY --chown=root:root deployment/docker/supervisord.conf /etc/supervisord.conf

RUN set -eux; \
    python -m pip install -U pip setuptools wheel; \
    python -m pip install -e /pretalx/[mysql,postgres,redis]; \
    python -m pip install gunicorn pylibmc; \
    rm -rf /root/.cache/pip

RUN chmod +x /usr/local/bin/pretalx

RUN set -eux; \
    python -m pretalx makemigrations; \
    python -m pretalx migrate; \
    python -m pretalx rebuild; \
    rm -f /pretalx/src/pretalx.cfg; \
    rm -f /pretalx/src/data/.secret; \
    chown -R pretalxuser:pretalxuser /pretalx /data /public /etc/pretalx

USER pretalxuser

VOLUME ["/etc/pretalx", "/data", "/public"]
EXPOSE 80
ENTRYPOINT ["pretalx"]
CMD ["all"]
