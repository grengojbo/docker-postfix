NAME = postfix
IMAGE_REPO = grengojbo
IMAGE_NAME = $(IMAGE_REPO)/$(NAME)
HOSTNAME = mail.example.com
DOMAIN = example.com
USERS = user:pwd
CONF_DIR = /var/lib/deis/store/postfix

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "   1. make build        - Build the postfix image"
	@echo "   2. make run          - Run postfix container"
	@echo "   3. make start        - Start postfix container"
	@echo "   4. make stop         - Stop postfix container"
	@echo "   5. make restart      - Stop and start postfix container"
	@echo "   6. make purge        - Stop and remove postfix container"
	@echo "   7. make state        - View state postfix container"
	@echo "   8. make logs         - View logs in real time"
	@echo ""

build:
	@echo "Build postfix..."
	@sudo docker build -t $(IMAGE_NAME) .

run:
	@mkdir -p $(CONF_DIR)/etc/opendkim/domainkeys
	@mkdir -p $(CONF_DIR)/etc/postfix/certs
	@echo "Run postfix..."
	@#-v $(CONF_DIR)/etc/aliases.db:/etc/aliases.db -v $(CONF_DIR)/etc/sasldb2:/etc/sasldb2
	@sudo docker run --name $(IMAGE_REPO)-$(NAME) -e MAIL_DOMAIN=$(DOMAIN) -e MAIL_HOSTNAME=$(HOSTNAME) -e smtp_user=$(USERS) -v $(CONF_DIR)/etc/opendkim/domainkeys:/etc/opendkim/domainkeys -v $(CONF_DIR)/etc/postfix/certs:/etc/postfix/certs --rm $(IMAGE_NAME)

start:
	@echo "Starting postfix..."
	@sudo docker start $(IMAGE_REPO)-$(NAME) > /dev/null

stop:
	@echo "Stopping postfix..."
	@sudo docker stop $(IMAGE_REPO)-$(NAME) > /dev/null

restart: stop start

purge: stop
	@echo "Removing postfix..."
	@sudo docker rm $(IMAGE_REPO)-$(NAME) > /dev/null

state:
	@sudo docker ps -a | grep $(IMAGE_REPO)-$(NAME)

logs:
	@sudo docker logs -f $(IMAGE_REPO)-$(NAME)