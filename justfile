start:
    docker compose up -d

stop:
    docker compose stop

shell:
    docker compose exec re bash

status:
    docker compose ps

logs:
    docker compose logs -f

restart:
    docker compose restart

build:
    docker compose build
