{
  description = "RuoYi";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux"];
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          temurin-bin-17  # 完整版 JDK17，含 AWT/字体支持，验证码生成需要
          mysql80
          redis
        ];

        shellHook = ''
          GREEN='\033[0;32m'
          YELLOW='\033[1;33m'
          NC='\033[0m'

          echo -e "$GREEN=== RuoYi 开发环境初始化中 ===$NC"

          # ── 使用 flake 提供的完整版 JDK，覆盖系统 headless JDK ──
          export JAVA_HOME="${pkgs.temurin-bin-17}"
          export PATH="$JAVA_HOME/bin:$PATH"

          export RUOYI_DEV_DIR="$PWD/.dev"
          export MYSQL_DATADIR="$RUOYI_DEV_DIR/mysql"
          export MYSQL_RUN_DIR="$RUOYI_DEV_DIR/mysql-run"
          export MYSQL_PORT=3306
          export MYSQL_SOCKET="$MYSQL_RUN_DIR/mysql.sock"
          export MYSQL_LOG="$RUOYI_DEV_DIR/mysql.log"

          export REDIS_DIR="$RUOYI_DEV_DIR/redis"
          export REDIS_PORT=6379
          export REDIS_LOG="$RUOYI_DEV_DIR/redis.log"
          export REDIS_PIDFILE="$RUOYI_DEV_DIR/redis.pid"

          # 日志目录（logback 默认写 /home/ruoyi/logs）
          export LOG_DIR="$PWD/.dev/logs"
          mkdir -p "$RUOYI_DEV_DIR" "$MYSQL_RUN_DIR" "$REDIS_DIR" "$LOG_DIR"

          # ── MySQL 初始化 ──
          if [ ! -d "$MYSQL_DATADIR" ]; then
            echo -e "$YELLOW[MySQL] 初始化数据目录...$NC"
            mysqld --initialize-insecure \
              --datadir="$MYSQL_DATADIR" \
              --user="$(whoami)" \
              2>>"$MYSQL_LOG"
          fi

          # ── MySQL 启动 ──
          if ! mysqladmin --socket="$MYSQL_SOCKET" ping --silent 2>/dev/null; then
            echo -e "$YELLOW[MySQL] 启动服务...$NC"
            mysqld \
              --datadir="$MYSQL_DATADIR" \
              --socket="$MYSQL_SOCKET" \
              --pid-file="$RUOYI_DEV_DIR/mysql.pid" \
              --port=$MYSQL_PORT \
              --log-error="$MYSQL_LOG" \
              --daemonize \
              2>>"$MYSQL_LOG"

            for i in $(seq 1 20); do
              mysqladmin --socket="$MYSQL_SOCKET" ping --silent 2>/dev/null && break
              sleep 0.5
            done
          fi

          # ── 建库建用户 ──
          mysql --socket="$MYSQL_SOCKET" -uroot 2>/dev/null <<'SQL' || true
            CREATE DATABASE IF NOT EXISTS ry
              DEFAULT CHARACTER SET utf8mb4
              DEFAULT COLLATE utf8mb4_general_ci;
            CREATE USER IF NOT EXISTS 'ruoyi'@'localhost' IDENTIFIED BY 'ruoyi123';
            GRANT ALL PRIVILEGES ON ry.* TO 'ruoyi'@'localhost';
            FLUSH PRIVILEGES;
SQL

          # ── 首次导入 sql/ 目录 ──
          INIT_FLAG="$RUOYI_DEV_DIR/.mysql_init_done"
          if [ ! -f "$INIT_FLAG" ] && [ -d "$PWD/sql" ]; then
            echo -e "$YELLOW[MySQL] 导入初始化 SQL...$NC"
            for sql_file in "$PWD/sql"/*.sql; do
              [ -f "$sql_file" ] && \
                mysql --socket="$MYSQL_SOCKET" -uroot ry < "$sql_file" && \
                echo "[MySQL] 已导入: $(basename $sql_file)"
            done
            touch "$INIT_FLAG"
          fi

          echo -e "$GREEN[MySQL] 就绪  port=$MYSQL_PORT  db=ry  user=root  pass=(空)$NC"

          # ── Redis 启动 ──
          if ! redis-cli -p $REDIS_PORT ping 2>/dev/null | grep -q PONG; then
            echo -e "$YELLOW[Redis] 启动服务...$NC"
            redis-server \
              --port $REDIS_PORT \
              --daemonize yes \
              --logfile "$REDIS_LOG" \
              --pidfile "$REDIS_PIDFILE" \
              --dir "$REDIS_DIR"
            sleep 1
          fi

          redis-cli -p $REDIS_PORT ping 2>/dev/null | grep -q PONG \
            && echo -e "$GREEN[Redis] 就绪  port=$REDIS_PORT$NC" \
            || echo "[Redis] 警告：启动失败，查看 $REDIS_LOG"

          # ── 退出时停止所有服务 ──
          stop_services() {
            echo -e "$YELLOW[Dev] 停止后台服务...$NC"
            mysqladmin --socket="$MYSQL_SOCKET" -uroot shutdown 2>/dev/null || true
            redis-cli -p $REDIS_PORT shutdown nosave 2>/dev/null || true
          }
          trap stop_services EXIT

          echo ""
          echo -e "$GREEN=== 常用命令 ===$NC"
          echo "  cd ruoyi-admin && mvn spring-boot:run   # 启动应用（先 cd 进子模块）"
          echo "  mvn clean install -DskipTests            # 全量编译"
          echo "  mysql --socket=\$MYSQL_SOCKET -uroot ry"
          echo "  redis-cli -p \$REDIS_PORT"
          echo ""
        '';
      };
    });
  };
}
