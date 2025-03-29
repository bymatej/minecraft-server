# Stage 1: Build Spigot
FROM debian:bookworm-slim AS spigot-builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip git ca-certificates gnupg apt-transport-https && \
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | \
    gpg --dearmor | tee /usr/share/keyrings/adoptium.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" \
    > /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    temurin-21-jdk maven && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-21-temurin-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

WORKDIR /spigot
RUN wget -O BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar --no-check-certificate && \
    java -jar BuildTools.jar --rev latest && \
    rm -rf ~/.m2 /root/.m2



# Stage 2: Final image
FROM debian:bookworm-slim

LABEL maintainer="programming@bymatej.com"
ARG DEBIAN_FRONTEND=noninteractive

ENV JAVA_MAJOR_VERSION=21
ENV MINECRAFT_FLAVOR="Vanilla" \
    MINECRAFT_VERSION=latest \
    MCMA_PASSWORD=nimda \
    WEBSERVER_PORT=8080 \
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

# Install core tools, dependencies, installed Java, add cleanup step
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    unzip \
    python3 \
    python3-pip \
    locales \
    ca-certificates \
    curl \
    git \
    screen \
    dumb-init \
    chromium \
    gosu \
    nano \
    gnupg \
    apt-transport-https \
    mono-runtime \
    xvfb \
    libnss3 \
    libatk-bridge2.0-0 \
    libx11-xcb1 \
    libxcomposite1 \
    libglib2.0-0 && \
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | \
    gpg --dearmor | tee /usr/share/keyrings/adoptium.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" \
    > /etc/apt/sources.list.d/adoptium.list && \
    apt update && \
    apt install -y --no-install-recommends temurin-${JAVA_MAJOR_VERSION}-jre && \
    apt autoclean && \
    apt autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8 \
    JAVA_HOME=/usr/lib/jvm/java-${JAVA_MAJOR_VERSION}-temurin-amd64 \
    PATH="/usr/lib/jvm/java-${JAVA_MAJOR_VERSION}-temurin-amd64/bin:$PATH"

# Setup McMyAdmin
WORKDIR /usr/local
RUN wget http://mcmyadmin.com/Downloads/etc.zip --no-check-certificate && \
    unzip etc.zip && \
    rm etc.zip

WORKDIR /McMyAdmin
RUN wget http://mcmyadmin.com/Downloads/MCMA2_glibc26_2.zip --no-check-certificate && \
    unzip MCMA2_glibc26_2.zip && \
    rm MCMA2_glibc26_2.zip && \
    ./MCMA2_Linux_x86_64 -setpass "$MCMA_PASSWORD" -configonly -nonotice

# Agree to EULA
RUN echo "***** Agreeing to MCMA's EULA: https://mcmyadmin.com/licence.html" && \
    touch /McMyAdmin/Minecraft/eula.txt && \
    echo "eula=true" >> /McMyAdmin/Minecraft/eula.txt

# Copy spigot server from builder
COPY --from=spigot-builder /spigot/spigot-*.jar /McMyAdmin/Minecraft/spigot/

# Add scripts and configs
COPY scripts/requirements.txt /scripts/
RUN pip3 install --no-cache-dir --break-system-packages -r /scripts/requirements.txt

COPY scripts/ /scripts/
COPY files/server.properties /McMyAdmin/Minecraft/server.properties

# Setup chromedriver (optional; remove if not used)
COPY chromedriver /chromedriver/chromedriver
RUN chmod a+x /chromedriver/chromedriver && \
    ln -s /chromedriver/chromedriver /usr/local/bin/chromedriver

# Final cleanup
RUN apt-get purge -y gnupg && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

# Ports and volumes
EXPOSE 8080 25565
VOLUME /McMyAdmin/
WORKDIR /McMyAdmin/

# Startup
RUN chmod +x /scripts/startup.sh /scripts/entrypoint.sh
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/scripts/startup.sh"]
