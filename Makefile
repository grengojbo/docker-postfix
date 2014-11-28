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
	@sudo docker build -t norsystechteam/postfix .

run:
	@echo "Run postfix..."
	@sudo docker run --name norsys-postfix -d -ti -p 25:25 -e maildomain=mail.example.com -e smtp_user=user:pwd norsystechteam/postfix

start:
	@echo "Starting postfix..."
	@sudo docker start norsys-postfix > /dev/null

stop:
	@echo "Stopping postfix..."
	@sudo docker stop norsys-postfix > /dev/null

restart: stop start

purge: stop
	@echo "Removing postfix..."
	@sudo docker rm norsys-postfix > /dev/null

state:
	@sudo docker ps -a | grep norsys-postfix

logs:
	@sudo docker logs -f norsys-postfix