0.7.pre
-------
* Update Celluloid to 0.16.0

0.6.4
-----
* leye: rename env variable EYEFILE to EYE_FILE
* leye: add options --eyefile and --eyehome #102
* leye: now store pid and sock into "DIR(eyefile)/.eye" (requires to leye quit && leye load)
* add dsl load_env method
* add trigger executing helpers :execute_sync, :execute_async
* add [triggers example](https://github.com/kostya/eye/blob/master/examples/triggers.eye)
* fix user command expand {PID} #104
* add EYE_CLIENT_TIMEOUT variable to set client timeout #99

0.6.3
-----
* Add custom logger #81
* Revert check by procline, this was hack, fix for #62 should be in 0.7
* Fix ruby path, and expand_paths #69, #75
* Add json info `eye info -j`
* Rename local runner to `leye`

0.6.2
-----
* Add user defined command #65
* eye status PROCESS_NAME, now return exit status for process name (0: up, 3: unmonitored) #68
* test pid from pid_file for eye-lwp (hackety), probably fix #62
* fix exclusive `eye load`

0.6.1
------
* Add log rotation gem (https://github.com/kostya/eye-rotate)
* Add option to clear environment variables #64
* Get group names from /etc/group via Etc#getgrnam #63

0.6
------
* add processes dependencies (#43)
* add eye-http gem (https://github.com/kostya/eye-http)
* add eye plugin example (https://github.com/kostya/eye/tree/master/examples/plugin)
* add quit option --stop_all (#39)
* add local eye runner (like foreman, used Eyefile)
* add use_leaf_child monitoring strategy (to daemonize sh -c '...') (788488a)
* add children_count, children_memory checks
* add dsl default application options (__default__)
* trusting external pid_file changes (#52)

0.5.2
-----
* rename dsl :childs_update_period to :children_update_period
* grammar fixes
* add checker option `above`

0.5.1
-----
* fix ordering in info (#27)
* add log rotation (#26)
* minor load fixes

0.5
-------
* little fixes in dsl
* remove activesupport dependency
* rename `state` trigger to `transition`
* add runtime, cputime, file_touched checks
* real cpu check (#9)
* use sigar gem instead of `ps ax`
* refactor cli (requires `eye q && eye l` after update gem from 0.4.x)
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
