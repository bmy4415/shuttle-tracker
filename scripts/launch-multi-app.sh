#!/bin/bash
# launch-multi-app.sh
# Launch 4 Flutter app instances for multi-user testing
# (1 Driver + 3 Parents)
#
# Strategy: Smart build + Parallel execution for maximum speed
# - Skip build if no source changes
# - Reuse Firebase if already running
# - Use html renderer for faster compile

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# App instances configuration
declare -a APPS=(
    "Driver:5001"
    "Parent1:5002"
    "Parent2:5003"
    "Parent3:5004"
)

# Project directory (where the script is run from)
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Build output directory
BUILD_DIR="build/web"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Shuttle App Multi-Instance Launcher  ${NC}"
echo -e "${BLUE}        (Optimized Version)            ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Firebase Emulators are already running
is_firebase_running() {
    local ui_ok=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000 2>/dev/null)
    local auth_ok=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9099 2>/dev/null)
    local firestore_ok=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null)
    local rtdb_ok=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9000 2>/dev/null)

    if [ "$ui_ok" = "200" ] && [ "$auth_ok" = "200" ] && [ "$firestore_ok" = "200" ] && [ -n "$rtdb_ok" ] && [ "$rtdb_ok" != "000" ]; then
        return 0  # Running
    fi
    return 1  # Not running
}

# Kill existing Firebase emulator processes
kill_firebase_emulators() {
    echo -e "${YELLOW}Stopping existing Firebase Emulators...${NC}"

    # Kill processes on Firebase Emulator ports
    for port in 4000 9099 8080 9000; do
        local pid=$(lsof -ti :$port 2>/dev/null)
        if [ -n "$pid" ]; then
            kill -9 $pid 2>/dev/null || true
        fi
    done

    # Also kill any firebase process
    pkill -f "firebase.*emulators" 2>/dev/null || true

    # Wait for ports to be released
    sleep 2
    echo -e "${GREEN}✓ Existing emulators stopped${NC}"
}

# Start fresh Firebase emulators
start_firebase_emulators() {
    echo -e "${YELLOW}Starting Firebase Emulators...${NC}"

    local log_file="/tmp/firebase_emulator.log"

    # Start Firebase Emulators in background
    cd "$PROJECT_DIR"
    nohup firebase emulators:start --project demo-shuttle-tracker > "$log_file" 2>&1 &

    # Wait for ALL emulator services to be ready
    local max_wait=90
    local waited=0
    echo -n "  Waiting for emulators"

    while [ $waited -lt $max_wait ]; do
        if is_firebase_running; then
            echo ""
            echo -e "${GREEN}✓ Firebase Emulators ready${NC}"
            echo -e "    Log: $log_file"
            sleep 2  # Extra wait for full initialization
            return 0
        fi
        echo -n "."
        sleep 2
        waited=$((waited + 2))
    done

    echo ""
    echo -e "${RED}✗ Firebase Emulators failed to start within ${max_wait}s${NC}"
    echo -e "${RED}  Check log: $log_file${NC}"
    return 1
}

# Ensure Firebase is running (start only if needed)
ensure_firebase_running() {
    if is_firebase_running; then
        echo -e "${GREEN}✓ Firebase Emulators already running${NC}"
        return 0
    else
        echo -e "${YELLOW}Firebase not running, starting...${NC}"
        kill_firebase_emulators 2>/dev/null || true
        echo ""
        start_firebase_emulators
        return $?
    fi
}

# Clear Firebase data only (not restart)
clear_firebase_data() {
    echo -e "${YELLOW}Clearing Firebase data...${NC}"

    # Clear Firebase Auth Emulator data (all users)
    if curl -s http://localhost:9099 > /dev/null 2>&1; then
        curl -s -X DELETE "http://localhost:9099/emulator/v1/projects/demo-shuttle-tracker/accounts" > /dev/null 2>&1
        echo -e "${GREEN}✓ Auth data cleared${NC}"
    fi

    # Clear Firebase Firestore Emulator data
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        curl -s -X DELETE "http://localhost:8080/emulator/v1/projects/demo-shuttle-tracker/databases/(default)/documents" > /dev/null 2>&1
        echo -e "${GREEN}✓ Firestore data cleared${NC}"
    fi

    # Clear Firebase Realtime Database Emulator data
    if curl -s http://localhost:9000 > /dev/null 2>&1; then
        curl -s -X DELETE "http://localhost:9000/.json?ns=demo-shuttle-tracker-default-rtdb" > /dev/null 2>&1
        echo -e "${GREEN}✓ Realtime DB data cleared${NC}"
    fi
}

# Clear Chrome profiles
clear_chrome_profiles() {
    for app in "${APPS[@]}"; do
        IFS=':' read -r name port <<< "$app"
        local profile_dir="/tmp/shuttle_chrome_profile_$port"
        if [ -d "$profile_dir" ]; then
            rm -rf "$profile_dir"
        fi
    done
    echo -e "${GREEN}✓ Chrome profiles cleared${NC}"
}

# Check if source files changed since last build
has_source_changes() {
    local build_file="$PROJECT_DIR/$BUILD_DIR/main.dart.js"

    # If build doesn't exist, need to build
    if [ ! -f "$build_file" ]; then
        return 0  # Need build
    fi

    # Check if any dart file is newer than the build
    local newer_files=$(find "$PROJECT_DIR/lib" -name "*.dart" -newer "$build_file" 2>/dev/null | head -1)

    if [ -n "$newer_files" ]; then
        return 0  # Has changes, need build
    fi

    # Also check pubspec.yaml
    if [ "$PROJECT_DIR/pubspec.yaml" -nt "$build_file" ]; then
        return 0  # pubspec changed, need build
    fi

    return 1  # No changes
}

# Build Flutter web app with optimizations
build_flutter_web() {
    echo -e "${YELLOW}Building Flutter web app...${NC}"

    cd "$PROJECT_DIR"

    # Build for web
    # --profile: faster builds (debug-like but optimized)
    # --no-tree-shake-icons: speeds up build
    # Note: --web-renderer removed in Flutter 3.35+
    if flutter build web --profile --no-tree-shake-icons 2>&1 | tail -10; then
        echo -e "${GREEN}✓ Flutter web build complete${NC}"
        return 0
    else
        echo -e "${RED}✗ Flutter web build failed${NC}"
        return 1
    fi
}

# Smart build: only build if source changed
smart_build() {
    if has_source_changes; then
        echo -e "${CYAN}Source changes detected, building...${NC}"
        build_flutter_web
        return $?
    else
        echo -e "${GREEN}✓ No source changes, using cached build${NC}"
        return 0
    fi
}

# Kill existing static server processes on our ports
kill_existing_servers() {
    echo -e "${YELLOW}Stopping existing servers on ports 5001-5004...${NC}"

    for app in "${APPS[@]}"; do
        IFS=':' read -r name port <<< "$app"
        local pid=$(lsof -ti :$port 2>/dev/null)
        if [ -n "$pid" ]; then
            kill -9 $pid 2>/dev/null || true
        fi
    done

    sleep 1
    echo -e "${GREEN}✓ Existing servers stopped${NC}"
}

# Serve static files using Python's http.server
serve_on_port() {
    local name=$1
    local port=$2
    local log_file="/tmp/serve_${name}_${port}.log"
    local build_path="$PROJECT_DIR/$BUILD_DIR"

    (cd "$build_path" && nohup python3 -m http.server "$port" --bind 127.0.0.1 > "$log_file" 2>&1 &)
    echo -e "${GREEN}✓ Serving $name on http://localhost:$port${NC}"
}

# Open Chrome with isolated profile
open_chrome_instance() {
    local name=$1
    local port=$2
    local profile_dir="/tmp/shuttle_chrome_profile_$port"

    open -na "Google Chrome" --args \
        --user-data-dir="$profile_dir" \
        --new-window \
        "http://localhost:$port"

    echo -e "${GREEN}✓ Opened Chrome for $name${NC}"
}

# Main execution
main() {
    local start_time=$(date +%s)
    echo -e "${YELLOW}Starting multi-app environment...${NC}"
    echo ""

    # Step 1: Kill existing servers
    kill_existing_servers
    echo ""

    # Step 2: Ensure Firebase is running (smart - reuse if possible)
    if ! ensure_firebase_running; then
        echo -e "${RED}Failed to ensure Firebase Emulators. Aborting.${NC}"
        exit 1
    fi
    echo ""

    # Step 3: Clear cached state
    clear_chrome_profiles
    clear_firebase_data
    echo ""

    # Step 4: Smart build (only if needed)
    if ! smart_build; then
        echo -e "${RED}Build failed. Aborting.${NC}"
        exit 1
    fi
    echo ""

    # Step 5: Serve on multiple ports
    echo -e "${YELLOW}Starting 4 servers...${NC}"
    for app in "${APPS[@]}"; do
        IFS=':' read -r name port <<< "$app"
        serve_on_port "$name" "$port"
    done
    echo ""

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  All instances ready! (${duration}s)${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}App URLs:${NC}"
    for app in "${APPS[@]}"; do
        IFS=':' read -r name port <<< "$app"
        echo -e "  ${name}: http://localhost:$port"
    done
    echo ""
    echo -e "${BLUE}Firebase Emulator UI: http://localhost:4000${NC}"
    echo ""
    echo -e "${YELLOW}To stop servers:${NC}"
    echo "  kill \$(lsof -ti :5001,:5002,:5003,:5004)"
}

main
