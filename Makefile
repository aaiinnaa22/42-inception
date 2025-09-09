
COMPOSE_FLAGS = docker-compose -f
COMPOSE_FILE= srcs/docker-compose.yml

.PHONY: all build up down logs restart clean
all: build up

build:
	$(COMPOSE_FLAGS) $(COMPOSE_FILE) build

up:
	$(COMPOSE_FLAGS) $(COMPOSE_FILE) up -d

down:
	$(COMPOSE_FLAGS) $(COMPOSE_FILE) down -v

clean:
	$(COMPOSE_FLAGS) $(COMPOSE_FILE) down -v --rmi all --remove-orphans
	docker system prune -af --volumes

logs:
	$(COMPOSE_FLAGS) $(COMPOSE_FILE) logs -f

restart: clean build up