#!/bin/bash
set -e

echo "***** Entrypoint..."
echo " -------------------- "

install_java() {
  # Update system
  echo "Running apt -y update"
  apt -y update

  # Install java
  echo "Installing Java version $JAVA_MAJOR_VERSION"
  apt -y install openjdk-"$JAVA_MAJOR_VERSION"-jdk-headless

  # Set JAVA_HOME environment variable
  JAVA_HOME="/usr/lib/jvm/java-${JAVA_MAJOR_VERSION}-openjdk-amd64/jre/bin/java"
  echo "***** Setting JAVA_HOME environment variable" && \
  echo "JAVA_HOME=/usr/lib/jvm/java-${JAVA_MAJOR_VERSION}-openjdk-amd64/jre/bin/java" >> /etc/profile && \
  echo "PATH=${PATH}:${HOME}/bin:${JAVA_HOME}/bin" >> /etc/profile && \
  echo "export JAVA_HOME" >> /etc/profile && \
  echo "export JRE_HOME" >> /etc/profile && \
  echo "export PATH" >> /etc/profile
}

install_vanilla() {
  # Install vanilla if required
  export SERVER_TYPE=Official
  if [ ! -f /McMyAdmin/Minecraft/.vanillaInstalled ] ; then
    echo "***** Installing Vanilla"
    python3 /scripts/download_minecraft_vanilla.py
    touch /McMyAdmin/Minecraft/.vanillaInstalled
    echo "***** Vanilla installation done!" ; else
      echo  "***** Minecraft Vanilla is already installed."
  fi
}

install_spigot() {
  # Install Spigot if required
  export SERVER_TYPE=Official
  if [ ! -f /McMyAdmin/Minecraft/spigot/.buildSuccess ] ; then
    echo "***** Installing Spigot"
    JVM_MAX_MEMORY="Xmx${JAVA_MEMORY}M"
    cd /McMyAdmin/Minecraft/spigot/
    java -"$JVM_MAX_MEMORY" -jar /McMyAdmin/Minecraft/spigot/BuildTools.jar --rev "$MINECRAFT_VERSION" > spigot.log 2>&1
    cp /McMyAdmin/Minecraft/spigot/spigot-*.jar /McMyAdmin/Minecraft/
    mv /McMyAdmin/Minecraft/minecraft_server.jar /McMyAdmin/Minecraft/minecraft_server.jar_backup
    mv /McMyAdmin/Minecraft/spigot-*.jar /McMyAdmin/Minecraft/minecraft_server.jar
    touch /McMyAdmin/Minecraft/spigot/.buildSuccess
    echo "***** Spigot installation done!" ; else
      echo  "***** Spigot is already installed."
  fi
}

install_paper() {
  # Install Paper if required
  export SERVER_TYPE=Official
  if [ ! -f /McMyAdmin/Minecraft/.paperInstalled ] ; then
    echo "***** Installing Paper"
    python3 /scripts/download_minecraft_paper.py
    touch /McMyAdmin/Minecraft/.paperInstalled
    echo "***** Paper installation done!" ; else
      echo  "***** Minecraft Paper is already installed."
  fi
}

install_forge() {
  export SERVER_TYPE=Forge
  # Install Forge if required
  if [ ! -f /McMyAdmin/Minecraft/ForgeMod.jar ] ; then
    echo "***** Installing Forge"
    python3 /scripts/download_minecraft_forge.py
    cd /McMyAdmin/Minecraft
    java -jar /McMyAdmin/Minecraft/forge-installer.jar --installServer /McMyAdmin/Minecraft
    rm /McMyAdmin/Minecraft/forge-installer.jar
    mv /McMyAdmin/Minecraft/forge-*.jar /McMyAdmin/Minecraft/ForgeMod.jar
    echo "***** Forge installation done!" ; else
      echo  "***** Minecraft Forge is already installed."
  fi
}

case ${MINECRAFT_FLAVOR^^} in
    VANILLA )
        install_vanilla
    ;;
    SPIGOT )
        install_spigot
    ;;
    PAPER )
        install_paper
    ;;
    FORGE )
        install_forge
    ;;
    * )
        echo "$MINECRAFT_FLAVOR is unknown. Vanilla flavor will be installed instead..."
        install_vanilla
    ;;
esac

# Configure McMyAdmin if required
echo "***** Configuring McMyAdmin conf file"
if [ ! -f /McMyAdmin/.mcma_configured ] ; then
  python3 /scripts/configure_mcma.py
  touch /McMyAdmin/.mcma_configured
  echo "***** McMyAdmin configuration is done!" ; else
      echo  "***** McMyAdmin is already configured."
fi

# Configure Minecraft if required
echo "***** Configuring Minecraft server properties file"
if [ ! -f /McMyAdmin/Minecraft/.minecraft_configured ] ; then
  python3 /scripts/configure_minecraft.py
  touch /McMyAdmin/Minecraft/.minecraft_configured
  echo "***** Minecraft server properties configuration is done!" ; else
      echo  "***** Minecraft server properties are already configured."
fi

cd /McMyAdmin/
echo "***** Starting up..."
./MCMA2_Linux_x86_64 -setpass "$MCMA_PASSWORD"

echo "***** Done!"
