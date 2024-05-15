FROM debian:bookworm

LABEL maintainer="programming@bymatej.com"

ARG DEBIAN_FRONTEND=noninteractive

# Environment variables used for setting up the system
ENV JAVA_MAJOR_VERSION=17

# Environment variables used for Mod installation
ENV MINECRAFT_FLAVOR="Vanilla"
ENV MINECRAFT_VERSION=latest

# Environment variables used for initialising McMyAdmin
ENV MCMA_PASSWORD=nimda

# Environment variables used in McMyAdmin.conf
ENV WEBSERVER_PORT=8080 \
    JAVA_PATH=detect \
    JAVA_MEMORY=1024 \
    JAVA_GC=default \
    JAVA_CUSTOM_OPTS=""

# Environment variables used in server.properties in Minecraft
ENV ENABLE_JMX_MONITORING=false \
    RCON_PORT=25575 \
    LEVEL_SEED="" \
    GAMEMODE=survival \
    ENABLE_COMMAND_BLOCK=false \
    ENABLE_QUERY=false \
    GENERATOR_SETTINGS="" \
    LEVEL_NAME=WORLD \
    MOTD="A Minecraft Server" \
    QUERY_PORT=25565 \
    PVP=true \
    GENERATE_STRUCTURES=true \
    DIFFICULTY=easy \
    NETWORK_COMPRESSION_THRESHOLD=256 \
    MAX_TICK_TIME=60000 \
    MAX_PLAYERS=20 \
    USE_NATIVE_TRANSPORT=true \
    ONLINE_MODE=true \
    ENABLE_STATUS=true \
    ALLOW_FLIGHT=false \
    BROADCAST_RCON_TO_OPS=true \
    VIEW_DISTANCE=10 \
    MAX_BUILD_HEIGHT=256 \
    SERVER_IP="" \
    ALLOW_NETHER=true \
    SERVER_PORT=25565 \
    ENABLE_RCON=false \
    SYNC_CHUNK_WRITES=true \
    OP_PERMISSION_LEVEL=4 \
    PREVENT_PROXY_CONNECTIONS=false \
    RESOURCE_PACK="" \
    ENTITY_BROADCAST_RANGE_PERCENTAGE=100 \
    RCON_PASSWORD="" \
    PLAYER_IDLE_TIMEOUT=0 \
    FORCE_GAMEMODE=false \
    RATE_LIMIT=0 \
    HARDCORE=false \
    WHITE_LIST=false \
    BROADCAST_CONSOLE_TO_OPS=true \
    SPAWN_NPCS=true \
    SPAWN_ANIMALS=true \
    SNOOPER_ENABLED=true \
    FUNCTION_PERMISSION_LEVEL=2 \
    LEVEL_TYPE=DEFAULT \
    SPAWN_MONSTERS=true \
    ENFORCE_WHITELIST=false \
    RESOURCE_PACK_SHA1="" \
    SPAWN_PROTECTION=16 \
    MAX_WORLD_SIZE=29999984

# Setup gecko driver
ADD chromedriver /chromedriver/chromedriver
RUN chmod a+x /chromedriver/chromedriver && \
    export PATH=$PATH:/chromedriver

# Update and install required software and tools
RUN echo "***** Updating and installing required software and tools" && \
    apt --assume-yes update && \
    apt --assume-yes install openjdk-$JAVA_MAJOR_VERSION-jre-headless \
                             wget \
                             zip \
                             unzip \
                             python3 \
                             python3-pip \
                             locales \
                             ca-certificates \
                             curl \
                             git \
                             screen \
                             dumb-init \
                             gosu \
                             chromium \
                             nano \
                             mono-complete \
                             xvfb

# Install Python dependencies
ADD scripts/requirements.txt /scripts/requirements.txt
RUN pip3 install -r /scripts/requirements.txt --break-system-packages

# General system setup
RUN echo "***** Running general system setup" && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-$JAVA_MAJOR_VERSION-openjdk-amd64/jre/bin/java
RUN echo "***** Setting JAVA_HOME environment variable" && \
    echo "JAVA_HOME=/usr/lib/jvm/java-$JAVA_MAJOR_VERSION-openjdk-amd64/jre/bin/java" >> /etc/profile && \
    echo "PATH=$PATH:$HOME/bin:$JAVA_HOME/bin" >> /etc/profile && \
    echo "export JAVA_HOME" >> /etc/profile && \
    echo "export JRE_HOME" >> /etc/profile && \
    echo "export PATH" >> /etc/profile

# Download and install Mono for McMyAdmin
WORKDIR /usr/local
RUN wget http://mcmyadmin.com/Downloads/etc.zip --no-check-certificate && \
    unzip etc.zip && \
    rm etc.zip

# Download McMyAdmin
WORKDIR /McMyAdmin
RUN wget http://mcmyadmin.com/Downloads/MCMA2_glibc26_2.zip --no-check-certificate && \
    unzip MCMA2_glibc26_2.zip && \
    rm MCMA2_glibc26_2.zip

# Run initial setup for McMyAdmin
RUN /McMyAdmin/MCMA2_Linux_x86_64 -setpass $MCMA_PASSWORD -configonly -nonotice

# Agree to EULA
RUN echo "***** Agreeing to MCMA's EULA: https://mcmyadmin.com/licence.html" && \
    touch /McMyAdmin/Minecraft/eula.txt && \
    echo "eula=true" >> /McMyAdmin/Minecraft/eula.txt

# Add McMyAdmin config script
ADD scripts/configure_mcma.py /scripts/

# Download Spigot BuildTools
WORKDIR /McMyAdmin/Minecraft/spigot/
RUN echo "***** Downloading Spigot BuildTools. Installation will happen on container start." && \
    wget -O BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar --no-check-certificate

# Add default Minecraft server.properties
ADD files/server.properties /McMyAdmin/Minecraft/server.properties

# Add Minecraft server config script
ADD scripts/configure_minecraft.py /scripts/

# Cleanup
RUN echo "***** Cleaning up" && \
    apt --assume-yes clean && \
    apt --assume-yes autoclean && \
    apt --assume-yes autoremove && \
    rm -rf \
           /tmp/* \
           /var/lib/apt/lists/* \
           /var/tmp/*

# Expose ports
EXPOSE 8080 25565

# Define volumes
WORKDIR /McMyAdmin/
VOLUME /McMyAdmin/

# Start
ADD scripts/ /scripts/
RUN chmod a+x /scripts/startup.sh && \
    chmod a+x /scripts/entrypoint.sh
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/scripts/startup.sh"]
