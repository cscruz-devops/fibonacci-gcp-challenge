# ---------- Build ----------
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /workspace

# Descarga dependencias sin copiar src todavía (cache más eficiente)
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline

# Copia el código y empaqueta jar "fat" (incluye dependencias)
COPY src ./src
RUN mvn -q -DskipTests clean package spring-boot:repackage

# ---------- Runtime ----------
FROM eclipse-temurin:17-jre
WORKDIR /app

# Cloud Run pasa PORT; por las dudas seteamos default
ENV PORT=8080

# Copiamos cualquier jar generado como app.jar (evita errores por nombre)
COPY --from=build /workspace/target/*.jar /app/app.jar

EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]



# # Build stage
# FROM maven:3.9-eclipse-temurin-17 AS build
# WORKDIR /app
# COPY pom.xml .
# RUN mvn -q -DskipTests dependency:go-offline
# COPY src ./src
# RUN mvn -q -DskipTests package

# # Runtime stage
# FROM eclipse-temurin:17-jre
# WORKDIR /app
# COPY --from=build /app/target/fibonacci-service-1.0.0.jar app.jar
# ENV PORT=8080
# EXPOSE 8080
# ENTRYPOINT ["java","-jar","/app/app.jar"]
