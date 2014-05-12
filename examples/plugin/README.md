Eye Plugin Example
------------------

This plugin adds reactor which try to reads command from file "/tmp/cmd.txt" every 1.second (then execute it and delete file). Also plugin add trigger to save every process state transition into "/tmp/saver.log".

To test it:

    bundle exec eye l examples/plugin/main.eye
    tail -f /tmp/eye.log
    tail -f /tmp/saver.log
    echo 'restart' > /tmp/cmd.txt

Also, here http example of gem:

    https://github.com/kostya/eye-http
