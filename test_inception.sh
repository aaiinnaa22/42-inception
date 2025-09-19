#!/bin/sh
# 42 Inception Tester (POSIX /bin/sh)
# Works with MariaDB Docker secret

GREEN="\033[1;32m"
RED="\033[1;31m"
NC="\033[0m"

HOST_HOST=localhost
EXPECTED="nginx wordpress mariadb"
# Get currently running containers
RUNNING=$(docker ps --format '{{.Names}}')
EXPECTED_NET="inception_net"
EXPECTED_VOLUMES="mariadb_data wordpress_data"
HOST_DIR="${HOME}/data"
. ./srcs/.env
MARIADB_ROOT_PASSWORD=$(cat ./secrets/mariadb_root_password.txt)
MARIADB_USER_PASSWORD=$(cat ./secrets/mariadb_user_password.txt)
WP_ADMIN_PASSWORD=$(cat ./secrets/wp_admin_password.txt)
WP_USER_PASSWORD=$(cat ./secrets/wp_user_password.txt)



ok() {
    printf "${GREEN}[OK]${NC} %s\n" "$1"
}

fail() {
    printf "${RED}[FAIL]${NC} %s\n" "$1"
    exit 1
}


###########################################

echo
echo "=== CHECKING RUNNING CONTAINERS ==="
echo
ALL_OK=1

for name in $EXPECTED; do
    echo "$RUNNING" | grep -w "$name" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        ok "Container '$name' is running"
    else
        fail "Expected container '$name' is NOT running"
        ALL_OK=0
    fi
done

# Check for unexpected containers
for container in $RUNNING; do
    echo "$EXPECTED" | grep -w "$container" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        fail "Unexpected container '$container' is running"
        ALL_OK=0
    fi
done

if [ $ALL_OK -eq 1 ]; then
    ok "All expected containers are running, no unexpected containers"
fi

###########################################

echo
echo "=== CHECKING PID 1 IN CONTAINERS ==="
echo
for container in $EXPECTED; do
    # Get the command of PID 1 inside the container
    CMD=$(docker top "$container" -eo pid,comm | awk 'NR==2 {print $2}')
    if [ -n "$CMD" ]; then
        ok "Container '$container' main process is PID 1 ($CMD)"
    else
        fail "Container '$container' main process not found / not PID 1"
    fi
done


###########################################

echo
echo "=== TESTING INTERNET AND HOST ACCESS TO THE CONTAINERS ==="
echo
echo "Testing WordPress (port 9000)..."
echo
nc -vz $HOST_HOST 9000 >/dev/null 2>&1 && fail "WordPress TCP reachable (should be blocked)" || ok "WordPress TCP unreachable (expected)"
curl -sf --connect-timeout 3 https://$HOST_HOST:9000 >/dev/null 2>&1 && fail "WordPress HTTPS reachable (should be blocked)" || ok "WordPress HTTPS blocked (expected)"
curl -sf --connect-timeout 3 http://$HOST_HOST:9000 >/dev/null 2>&1 && fail "WordPress HTTP reachable (should be blocked)" || ok "WordPress HTTP blocked (expected)"

echo
echo "Testing MariaDB (port 3306)..."
echo
nc -vz $HOST_HOST 3306 >/dev/null 2>&1 && fail "MariaDB TCP reachable (should be blocked)" || ok "MariaDB TCP unreachable (expected)"
curl -sf --connect-timeout 3 https://$HOST_HOST:3306 >/dev/null 2>&1 && fail "MariaDB HTTPS reachable (should be blocked)" || ok "MariaDB HTTPS blocked (expected)"
curl -sf --connect-timeout 3 http://$HOST_HOST:3306 >/dev/null 2>&1 && fail "MariaDB HTTP reachable (should be blocked)" || ok "MariaDB HTTP blocked (expected)"

echo
echo "Testing NGINX (port 443)..."
echo
nc -vz $HOST_HOST 443 >/dev/null 2>&1 && ok "NGINX TCP reachable (expected)" || fail "NGINX TCP unreachable"
curl -sf --connect-timeout 3 http://$HOST_HOST:443 >/dev/null 2>&1 && fail "NGINX HTTP succeeded (should fail)" || ok "NGINX HTTP blocked (expected)"
curl -ks --connect-timeout 3 https://$HOST_HOST:443 >/dev/null 2>&1 && ok "NGINX HTTPS succeeded (expected)" || fail "NGINX HTTPS failed (should work)"


echo
echo "Testing NGINX (port 80)..."
echo
nc -vz $HOST_HOST 80 >/dev/null 2>&1 && fail "NGINX TCP 80 reachable (should NOT be exposed)" || ok "NGINX TCP 80 unreachable (expected)"
curl -sf --connect-timeout 3 http://$HOST_HOST:80 >/dev/null 2>&1 && fail "NGINX HTTP on 80 succeeded (should NOT be exposed)" || ok "NGINX HTTP on 80 blocked (expected)"


###########################################

echo
echo "=== CHECKING THAT NETWORK '$EXPECTED_NET' EXISTS ==="
docker network ls --format '{{.Name}}' | grep -w "$EXPECTED_NET" >/dev/null 2>&1
echo
if [ $? -eq 0 ]; then
    ok "Network '$EXPECTED_NET' exists"
else
    fail "Network '$EXPECTED_NET' not found"
fi

###########################################

echo
echo "=== CHECKING THAT ALL EXPECTED CONTAINERS ARE CONNECTED TO '$EXPECTED_NET' ==="
echo
for container in $EXPECTED; do
    docker network inspect "$EXPECTED_NET" --format '{{range .Containers}}{{.Name}} {{end}}' | grep -w "$container" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        ok "Container '$container' is connected to '$EXPECTED_NET'"
    else
        fail "Container '$container' is NOT connected to '$EXPECTED_NET'"
    fi
done


###########################################



###########################################


echo
echo "=== TESTING WORDPRESS -> MARIADB (3306) ==="
echo
docker exec -i wordpress sh -c "nc -vz mariadb 3306 >/dev/null 2>&1"
if [ $? -eq 0 ]; then
    ok "WordPress can reach MariaDB on 3306"
else
    fail "WordPress cannot reach MariaDB on 3306"
fi

echo
echo "=== TESTING NGINX -> WordPress (9000) ==="
echo
docker exec -i nginx sh -c "nc -vz wordpress 9000 >/dev/null 2>&1"
if [ $? -eq 0 ]; then
    ok "NGINX can reach WordPress on 9000"
else
    fail "NGINX cannot reach WordPress on 9000"
fi

echo
echo "=== TESTING WORDPRESS -> NGINX (443) ==="
echo
docker exec -i wordpress sh -c "nc -vz nginx 443 >/dev/null 2>&1"
if [ $? -eq 0 ]; then
    ok "WordPress can reach NGINX on 443"
else
    fail "WordPress cannot reach NGINX on 443"
fi

echo
echo "=== TESTING MARIADB -> WORDPRESS (9000) ==="
echo
docker exec -i mariadb sh -c "nc -vz wordpress 9000 >/dev/null 2>&1"
if [ $? -eq 0 ]; then
    ok "MariaDB can reach WordPress on 9000"
else
    fail "MariaDB cannot reach WordPress on 9000 (expected if firewalled)"
fi

###########################################

echo
echo "=== CHECKING DOCKER VOLUMES ==="
echo
# Check that all expected volumes exist
for volume in $EXPECTED_VOLUMES; do
    docker volume ls --format '{{.Name}}' | grep -w "$volume" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        ok "Volume '$volume' exists"
    else
        fail "Volume '$volume' does NOT exist"
    fi
done

# Check for unexpected volumes
RUNNING_VOLUMES=$(docker volume ls --format '{{.Name}}')
for vol in $RUNNING_VOLUMES; do
    echo "$EXPECTED_VOLUMES" | grep -w "$vol" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        fail "Unexpected volume '$vol' exists"
    fi
done

ok "No unexpected volumes found"


###########################################

echo
echo "=== CHECKING DOCKER VOLUMES HOST DIRECTORIES ==="
echo

for vol in $EXPECTED_VOLUMES; do
    # Check the HOST directory exists (mariadb_data -> /home/login/data/mariadb, etc.)
    DIR_PATH="$HOST_DIR/${vol%%_data}"  # strip "_data" suffix
    if [ -d "$DIR_PATH" ]; then
        ok "HOST directory '$DIR_PATH' exists"
    else
        fail "HOST directory '$DIR_PATH' does NOT exist"
    fi
done

###########################################
echo
echo "=== CHECKING WORDPRESS USERS IN DATABASE ==="
echo
# Query all WordPress users and their roles

USERS=$(docker exec -i mariadb \
  sh -c "mariadb -u\"$MARIADB_USER\" -p\"$MARIADB_USER_PASSWORD\" -D \"$DATABASE\" -N -e 'SELECT u.user_login, m.meta_value FROM wp_users u JOIN wp_usermeta m ON u.ID=m.user_id WHERE m.meta_key=\"wp_capabilities\";'")


echo "Users found:"
printf '%s\n' "$USERS" | awk '{print $1}'
echo

USER_COUNT=$(printf '%s\n' "$USERS" | wc -l | tr -d ' ')
[ "$USER_COUNT" -eq 2 ] && ok "Exactly 2 WordPress users found" || fail "Expected 2 users, found $USER_COUNT"

# Check for administrator
ADMIN_NAME=""
TMPFILE=$(mktemp)
printf '%s\n' "$USERS" > "$TMPFILE"

while IFS=$'\t' read -r USERNAME ROLE; do
    echo "$ROLE" | grep -qi 'administrator' && ADMIN_NAME="$USERNAME"
done < "$TMPFILE"

rm -f "$TMPFILE"

[ -n "$ADMIN_NAME" ] && ok "Administrator user exists: '$ADMIN_NAME'" || fail "No administrator user found"

# Validate admin username
echo "$ADMIN_NAME" | grep -qi 'admin\|administrator' && fail "Administrator username '$ADMIN_NAME' contains forbidden word" || ok "Administrator username '$ADMIN_NAME' is valid"



###########################################