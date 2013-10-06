0.5.pre
-------
* rename `state` trigger to `transition`
* add runtime, cputime checks
* real cpu check
* use sigar gem instead of `ps axo`
* refactor cli
* update celluloid to 0.15

0.4.2
-----
* add checker options :initial_grace, :skip_initial_fails
* allow deleting env variables (#15)

0.4.1
---------
* add nop checker for periodic restart
* catch errors in custom checkers, triggers
* add custom notify
* checker can fires array of commands
* fix targets matching
* remove autoset PWD env

0.4
---------
* pass tests on 1.9.2
* relax activesupport dependency
* change client-server protocol (requires `eye q && eye l` after update gem from 0.3.x)
* not matching targets from different applications
* improve triggers (custom, better flapping)
* delete pid_file on crash for daemonize process
* delete pid_file on stop for all process types (`clear_pid false` to disable)
* parallel tests (from 30 mins to 3min)
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
