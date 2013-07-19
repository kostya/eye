0.4.dev
---------
* on stop cleanup pid_file by default for all process types (`clear_pid false` to disable)
* update celluloid to 0.14

0.3.2
---------
* improve matching targers
* possibility to add many checkers with the same type per process (ex: checks :http_2, ...)
* add uid, gid options (only for ruby 2.0)

0.3.1
-----
* load multiple configs (folder,...) now not breaks on first error (each config loads separately)
* load ~/.eyeconfig with first eye load
* some concurrency fixes
* custom checker

0.3
---
* stable version
