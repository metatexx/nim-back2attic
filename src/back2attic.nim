import strutils
import os
import parseopt2
import osproc
import streams
import times
import mysql


# Following SQL to create a Flush/Lock User (without password)

# CREATE USER attic@localhost;
# GRANT LOCK TABLES, RELOAD ON *.* TO attic@localhost

const version="1.0.0"

const db_user="attic"
const db_password="" # probably not needed

# not really important as just temporary
const snap_name="atticsnap"
const snap_mountpoint="/mnt/atticsnap"

# following needs to match your system!
const snap_source="/dev/mapper/vg00-lv_root"
const snap_target="/dev/mapper/vg00-" & snap_name

# LVM tools throw warnings about leaking filedescriptors
# I think they can be safely ignored here
putEnv("LVM_SUPPRESS_FD_WARNINGS","1")

type EKeyboardInterrupt =
  object of Exception

template mRaise(m: string) =
  var e = new IOError
  e.msg = m
  raise e

template mRaise(con: PMySQL) =
  var e = new IOError
  e.msg = $ mysql.error(con)
  raise e

template traceIt(m: string, doit: stmt): stmt =
  echo "Trace: ", m
  doit

proc runCmd(cmd: string, args: openArray[string]) =
  var myProc = startProcess(cmd, "", args)
  var myStdout = myProc.outputStream()
  while true:
    var line: TaintedString = ""
    if readLine(myStdout, line):
      echo line
    else:
      break

proc handler() {.noconv.} =
  echo "\lControl-C detected. Aborting..."
  raise newException(EKeyboardInterrupt, "Keyboard Interrupt")

proc main(backupScript: string) = 
  let con: PMySQL = mysql.init(nil)
  if con == nil: mRaise "init failed"

  echo "Connecting to MySQL"
  if mysql.realConnect(con, "localhost", db_user, db_password, "", 0, nil, 0) == nil:
    defer: traceIt "close con", mysql.close(con)
    mRaise con

  echo "Flushing MySQL Tables"
  let q1 = "FLUSH TABLES WITH READ LOCK"
  if mysql.realQuery(con, q1, q1.len) != 0: mRaise con

  echo "Creating LVM snapshot"
  runCmd("/sbin/lvcreate", ["-l", "100%FREE", "-s", "-n", snap_name, snap_source])

  try:
    let q2 = "UNLOCK TABLES"
    if mysql.realQuery(con, q2, q2.len) != 0: mRaise con
    echo "Unlocked MySQL Tables"

    createDir(snap_mountpoint)

    try:
      echo "Mounting snapshot"
      runCmd("/bin/mount", [snap_target, snap_mountpoint])

      # backup
      let t = getTime().getLocalTime()

      echo "Running backup script at ", t.format("yyyy-MM-dd HH:mm:ss")
      runCmd(backupScript,[])
      echo "Finished backup script at ", t.format("yyyy-MM-dd HH:mm:ss")

    finally:
      runCmd("/bin/umount", [snap_target])
      echo "Unmounted snapshot"

  finally:
    runCmd("/sbin/lvremove", ["-f", snap_target])
    echo "Removed LVM snapshot"


proc writeVersion() =
  echo "Version ", version

proc writeHelp() =
  echo "back2attic <backup-script>"

when isMainmodule:
  setControlCHook(handler)
  try:
    var backupScript = ""

    for kind, key, val in getopt():
      case kind

      of cmdArgument:
        backupScript = key

      of cmdLongOption, cmdShortOption:
        case key
        of "help", "h": writeHelp()
        of "version", "v": writeVersion()
        else: writeHelp()

      of cmdEnd: assert(false) # cannot happen
    
    if backupScript == "":
      # no filename has been given, so we show the help:
      writeHelp()
    else:
      main(backupScript)

  except EKeyboardInterrupt:
    echo "Aborted!"
