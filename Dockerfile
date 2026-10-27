FROM python:3.12-slim AS build
WORKDIR /site

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY mkdocs.yml .
COPY docs docs

ARG SITE_URL=http://localhost:8080/
ENV SITE_URL=${SITE_URL}
RUN mkdocs build --strict

# ---- Stage 2: serve it ----
FROM nginxinc/nginx-unprivileged:stable-alpine
COPY --from=build /site/site /usr/share/nginx/html
EXPOSE 8080
