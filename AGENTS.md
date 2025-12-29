# PiGation Server (pig_server) Notes

## Overview
- Dart-based web server and installer for a Raspberry Pi irrigation system with an embedded web UI.
- CLI entrypoint `pig` handles install, launch (watchdog), and server modes.
- Uses `shelf` for HTTP/HTTPS, `shelf_letsencrypt` for certs, and SQLite via `sqflite_common_ffi`.

## Key Entry Points
- `bin/pig.dart`: CLI flags (`--install`, `--launch`, `--server`, `--debug`) and process lifecycle.
- `lib/src/startup/install.dart`: interactive install + deploy to `/opt/pigation`.
- `lib/src/startup/launch.dart`: watchdog launcher for the server.
- `lib/src/http/web_server.dart`: HTTP/HTTPS server startup and LetsEncrypt renewal.
- `lib/src/http/handlers/*`: REST endpoints and static file delivery.
- Tooling: `tool/` is for non-deployed utilities; `bin/` is for deployed code.

## Runtime/Install Flow
- Install uses `sudo pig --install`, collects config, sets up `/opt/pigation`, and sets capabilities for port 80/443.
- Web UI content is copied into `/opt/pigation/www_root` and served from there.
- Server runs in foreground with `pig --server`; watchdog uses `pig --launch`.

## Quick start
- `cd pig_server`
- `dart run bin/pig.dart --server --debug`
- Dev config lives at `pig_server/config/config.yaml`

## Configuration
- Config file: `/opt/pigation/config/config.yaml` in production or `config/config.yaml` for dev.
- Important keys: `path_to_static_content`, `fqdn`, `http_port`, `https_port`, `domain_email`, `use_https`, `production`.

## Data/Backups
- SQLite DB at `/opt/pigation/database/pigation.db`.
- Backups stored under `backups/` (zip archives) managed by `LocalBackupProvider`.

## Tests
- Unit tests use `dart test` (see `test/` directory). No explicit test runner scripts.

## Linting
- This repo uses `lint_hard` and is strict about analysis warnings.

## Review Notes (Potential Issues)
- `bin/pig.dart` configures `Self` with `installPath: '$HOME/myapp'` and `executableName: 'myapp'`, which doesn’t align with `/opt/pigation` install paths.
- `lib/src/http/web_server.dart` reports an HTTPS URL even when `use_https` is false.
- `lib/src/startup/install.dart` hard-codes ownership of `/opt/pigation/www_root` to user `bsutton`, which breaks installs for other users.
