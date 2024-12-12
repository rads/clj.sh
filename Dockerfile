FROM clojure:tools-deps-1.12.0.1479-bookworm-slim
WORKDIR /app
COPY . .
RUN apt-get update && apt-get upgrade -y && apt-get install curl -y
RUN clojure -M:aot
ENTRYPOINT ["clojure", "-M:prod"]
