FROM debian:bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    autoconf \
    automake \
    autoconf-archive \
    libtool \
    libltdl-dev \
    pkg-config \
    libpq-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libboost-thread-dev \
    liboath-dev \
    libpcre3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .

# autogen.sh runs aclocal before libtoolize, which leaves stale libtool macros
# in aclocal.m4 when the installed libtool version differs from what was committed.
# Run the steps manually in the correct order instead.
RUN libtoolize --force --automake --copy --ltdl \
    && aclocal -I m4 \
    && autoconf \
    && autoheader \
    && automake -a -c \
    && ./configure \
        --prefix=/app \
        --with-optimization \
        --without-debug \
        --enable-modules=cservice,ccontrol \
    && make -j"$(nproc)" \
    && make install

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    libssl3 \
    libcurl4 \
    libboost-thread1.74.0 \
    liboath0 \
    libltdl7 \
    libpcre3 \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Built + installed gnuworld tree (binary, libs, migrations, server_command_map)
COPY --from=builder /app /app

# SQL schemas for first-run database initialization
COPY doc/cservice.sql              /app/sql/cservice/01-cservice.sql
COPY doc/cservice.languages.sql    /app/sql/cservice/02-languages.sql
COPY doc/cservice.translations.sql /app/sql/cservice/03-translations.sql
COPY doc/cservice.help.sql         /app/sql/cservice/04-help.sql
COPY doc/cservice.config.sql       /app/sql/cservice/05-config.sql
COPY doc/cservice.addme.sql        /app/sql/cservice/06-addme.sql

COPY doc/ccontrol.sql              /app/sql/ccontrol/01-ccontrol.sql
COPY doc/ccontrol.help.sql         /app/sql/ccontrol/02-help.sql
COPY doc/ccontrol.addme.sql        /app/sql/ccontrol/03-addme.sql
COPY doc/ccontrol.commands.sql     /app/sql/ccontrol/04-commands.sql

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# gnuworld resolves libdir and command_map relative to its CWD
WORKDIR /app/bin

ENTRYPOINT ["/entrypoint.sh"]
