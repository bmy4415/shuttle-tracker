Launch 4 Flutter app instances for multi-user testing (1 Driver + 3 Parents).

Run the multi-app launch script:
```bash
./scripts/launch-multi-app.sh
```

The script automatically handles:
- Firebase Emulator (starts if not running, reuses if running)
- Smart build (builds only when source files changed)
- 4 servers on ports 5001-5004

App URLs after launch:
- Driver: http://localhost:5001
- Parent1: http://localhost:5002
- Parent2: http://localhost:5003
- Parent3: http://localhost:5004
- Firebase UI: http://localhost:4000

To stop servers:
```bash
kill $(lsof -ti :5001,:5002,:5003,:5004)
```
