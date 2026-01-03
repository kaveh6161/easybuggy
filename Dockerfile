# Build stage - using Eclipse Temurin (OpenJDK replacement)
FROM maven:3.9.12-eclipse-temurin-8-noble AS builder
COPY . /usr/src/easybuggy/
WORKDIR /usr/src/easybuggy/
RUN mvn -B package -DskipTests

# Runtime stage - using Eclipse Temurin slim image
FROM eclipse-temurin:25.0.1_8-jre-alpine-3.23

WORKDIR /app
COPY --from=builder /usr/src/easybuggy/target/easybuggy.jar /app/

# Create directories needed by the embedded Tomcat and application
# - logs/ for application logs
# - .extract/webapps/ is where embedded Tomcat extracts the webapp
RUN mkdir -p /app/logs /app/.extract/webapps && \
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
