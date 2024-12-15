FROM postgres:latest

ENV POSTGRES_USER=root
ENV POSTGRES_PASSWORD=root
ENV POSTGRES_DB=postgres

COPY ./db_init /docker-entrypoint-initdb.d/