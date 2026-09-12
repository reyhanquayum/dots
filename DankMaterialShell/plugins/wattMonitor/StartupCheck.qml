import QtQuick
import qs.Common

// Blocks activation unless Watt and the status helper are installed.
QtObject {
    function check(done) {
        Proc.runCommand("watt.depCheck", ["sh", "-c", "command -v watt && test -x /usr/local/bin/dms-watt-status"], function (stdout, exitCode) {
            if (exitCode === 0) {
                done(null)
                return
            }
            done({
                "title": "Watt is required",
                "details": "This plugin needs the 'watt' binary and the '/usr/local/bin/dms-watt-status' helper on your PATH. Install Watt first and re-enable the plugin."
            })
        })
    }
}
