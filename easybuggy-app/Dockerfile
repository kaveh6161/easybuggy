# Build stage - using Eclipse Temurin (OpenJDK replacement)
FROM maven:3.9.12-eclipse-temurin-8-noble AS builder
COPY . /usr/src/easybuggy/
WORKDIR /usr/src/easybuggy/
RUN mvn -B package -DskipTests

# Runtime stage - using Eclipse Temurin JDK 8 (same version as build)
# Note: The embedded Tomcat7 runner has compatibility issues with newer JDKs
FROM eclipse-temurin:8-jdk-jammy

WORKDIR /app
COPY --from=builder /usr/src/easybuggy/target/easybuggy.jar /app/

# Create logs directory for application logs
# Note: Do NOT pre-create .extract directory - the Tomcat7Runner needs to create it
# during extraction to properly populate the webappWarPerContext map
RUN mkdir -p /app/logs && \
    chmod -R 777 /app

# Expose application port and debug port
EXPOSE 8080 9009

CMD ["java", \
    "-XX:MaxMetaspaceSize=128m", \
    "-Xmx256m", \
    "-XX:MaxDirectMemorySize=90m", \
    "-XX:+UseSerialGC", \
    "-XX:+HeapDumpOnOutOfMemoryError", \
    "-XX:HeapDumpPath=logs/", \
    "-XX:ErrorFile=logs/hs_err_pid%p.log", \
    "-agentlib:jdwp=transport=dt_socket,server=y,address=9009,suspend=n", \
    "-Dderby.stream.error.file=logs/derby.log", \
    "-Dderby.infolog.append=true", \
    "-Dderby.language.logStatementText=true", \
    "-Dderby.locks.deadlockTrace=true", \
    "-Dderby.locks.monitor=true", \
    "-Dderby.storage.rowLocking=true", \
    "-Dcom.sun.management.jmxremote", \
    "-Dcom.sun.management.jmxremote.port=7900", \
    "-Dcom.sun.management.jmxremote.ssl=false", \
    "-Dcom.sun.management.jmxremote.authenticate=false", \
    "-ea", \
    "-jar", "easybuggy.jar"]
