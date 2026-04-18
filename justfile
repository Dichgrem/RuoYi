set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
    @just --list

init:
    @mkdir -p .dev/mysql .dev/mysql-run .dev/redis .dev/logs
    @if [ ! -d .dev/mysql/mysql ]; then \
      mysqld --initialize-insecure --datadir=.dev/mysql --user="$$(whoami)" 2>>.dev/mysql.log; \
    fi
    @just start-db
    @mysql --socket=.dev/mysql-run/mysql.sock -uroot -e "CREATE DATABASE IF NOT EXISTS ry DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_general_ci;"
    @if [ ! -f .dev/.sql_init_done ]; then \
      for f in sql/*.sql; do [ -f "$$f" ] && mysql --socket=.dev/mysql-run/mysql.sock -uroot ry < "$$f"; done; \
      touch .dev/.sql_init_done; \
    fi

start: init
    @if ! redis-cli -p 6379 ping 2>/dev/null | grep -q PONG; then \
      redis-server --port 6379 --daemonize yes --dir .dev/redis --logfile .dev/redis.log --pidfile .dev/redis.pid; \
    fi
    @cd ruoyi-admin && mvn spring-boot:run

start-db:
    @if ! mysqladmin --socket=.dev/mysql-run/mysql.sock ping --silent >/dev/null 2>&1; then \
      mysqld --datadir=.dev/mysql --socket=.dev/mysql-run/mysql.sock --pid-file=.dev/mysql.pid --port=3306 --log-error=.dev/mysql.log --daemonize; \
      sleep 3; \
    fi

stop:
    @mysqladmin --socket=.dev/mysql-run/mysql.sock -uroot shutdown >/dev/null 2>&1 || true
    @redis-cli -p 6379 shutdown nosave >/dev/null 2>&1 || true
    @pkill -f 'com.ruoyi.RuoYiApplication' >/dev/null 2>&1 || true

build:
    @mvn clean package -DskipTests

test:
    @mvn test
