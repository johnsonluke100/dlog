FROM eclipse-temurin:17-jdk-focal

# Create an unprivileged user and server directory
RUN useradd -m -u 10002 velocity && \
    mkdir -p /home/velocity/server && \
    chown -R velocity:velocity /home/velocity

USER velocity
WORKDIR /home/velocity/server

# Bring in the proxy bits (make sure these exist in the build context)
COPY velocity.jar ./velocity.jar
COPY velocity.toml ./velocity.toml
COPY forwarding.secret ./forwarding.secret
COPY plugins ./plugins

# Default ports: Java 25565 TCP, Bedrock 19132 UDP
EXPOSE 25565/tcp 19132/udp

# Light JVM sizing; adjust as needed
CMD ["java","-Xms512M","-Xmx1024M","-jar","velocity.jar"]
