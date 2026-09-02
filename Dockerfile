FROM perl:5.38-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    iproute2 \
    iptables \
    libdbi-perl \
    libdbd-mysql-perl \
    libcurses-perl \
    libjson-perl \
    libsnmp-perl \
    libsnmp-session-perl \
    librrdtool-oo-perl \
    libwww-perl \
    libtry-tiny-perl \
    && rm -rf /var/lib/apt/lists/*

# Install Perl dependencies
RUN cpanm --notest \
    DBI \
    DBD::mysql \
    Curses::Application \
    JSON \
    Try::Tiny \
    LWP::UserAgent \
    HTTP::Request \
    Digest::MD5 \
    RRDTool::OO

# Create app directory
WORKDIR /opt/ptc

# Copy application code
COPY lib/ lib/
COPY bin/ bin/
COPY etc/ etc/

# Create tmp directory for runtime files
RUN mkdir -p /opt/ptc/tmp

# Copy entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["perl", "-Ilib", "bin/InfoScreen"]
