FROM perl:5.38-slim

# Install system dependencies
# Note: On Debian 11+, iptables is iptables-nft by default (nftables backend)
RUN apt-get update && apt-get install -y --no-install-recommends \
    iproute2 \
    iptables \
    nftables \
    # Build deps for Perl XS modules
    gcc \
    make \
    pkg-config \
    libmariadb-dev \
    libncurses-dev \
    librrd-dev \
    # Runtime deps
    libsnmp-perl \
    rrdtool \
    && rm -rf /var/lib/apt/lists/*

# Install Perl dependencies via cpanm
RUN cpanm --notest \
    DBI \
    DBD::MariaDB \
    Curses \
    Curses::Application \
    JSON \
    Try::Tiny \
    LWP::UserAgent \
    HTTP::Request \
    Digest::MD5 \
    RRDTool::OO \
    && rm -rf /root/.cpanm

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
