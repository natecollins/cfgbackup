CFGBACKUP - Simple File Backups
========================================
An easy to use file backup script where each job is based around a simple config file.  
 - All backups are just files in directories, no special tools for recovery
 - Very few dependencies - only standard open source tools, like Bash and rsync
 - Does rotational backups or simple syncing
 - Greatly reduce disk usage by hard linking files between rotationals
 - Email notifications on failure
 - Optional notification on file change/delete attempts
 - Pull backup source remotely over SSH
 - Customizable rotational directory names
 - And much more!

* [Requirements](#requirements)
* [Basic Usage](#basic-usage)
* [Config Options](#config-options)
* [More Details](#more-details)


Requirements
------------------------
- Bash Shell 4.3+
- rsync
- awk
- sed
- GNU Coreutils

Recommended
------------------------
- rsync 3.1.0+
- hardlink


Basic Usage
------------------------
There are two basic types of backup jobs `cfgbackup` can do: sync and rotation  
 - `sync` jobs syncronize a directory from one location to another
 - `rotation` jobs create a series of backups rotations in subdirs of the target dir

Each backup job has it's own config file. Provided is an example one called `example.conf`;
copy this file to your own file name in a logical location (suggested `/etc/cfgbackup/`).  

In this file, you will need to specify a few required options.  
`BACKUP_TYPE` which can be either `rotation` or `sync`  
`SOURCE_DIR` which is the directory to be backed up (can be remote over SSH)  
`TARGET_DIR` is where the backup(s) should go; must be a local directory  
`MAX_ROTATIONS` how many rotation subdirs to create (`rotation` jobs only)  

An example config file, let's call it `alpha.conf`, might be something like this:
```
BACKUP_TYPE=rotation
SOURCE_DIR=/var/data/
TARGET_DIR=/mnt/backups/alpha/
MAX_ROTATIONS=20
```

By default, `cfgbackup` will try to save log files into the `/var/log/cfgbackup/` directory.
Make sure that directory is either writable to or creatable by whatever user you will be using
to run the script as. Or you can change the log directory with the `LOG_DIR` config option.  

The `cfgbackup` script is run in the format of:  
```
./cfgbackup [config] [command]
```

The `[config]` is just the path to the config file you want to use. The `[command]` can be one
of a number of commands, enumerated below.  

**Check Command**  
The `check` command will check the config passed for errors.  
```
./cfgbackup alpha.conf check
```

If something wrong is detected in the config file, a message will display describing the error.  

If no problems are detected, it will respond with `Config is OK.`.  

**Run Command**  
The `run` command will attempt to start a job for the given config file. It will validate the
config first, same as the `check` command, and then verify that there isn't already a job
running. If a job is running, or a previously started job did not complete, then an error
message will display and the script will exit.  
```
./cfgbackup alpha.conf run
```

A successfully started job will run in the foreground and will not output anything to the
terminal. Ideally, most jobs will be started using the cron daemon, so terminal output is
not desired. To see what is happening with a running job, you can inspect the log file,
which you can customize with config options. The default log file name will be based on
the config filename and the date. With default options, a config file name of `alpha.conf`,
and a date of 2016-12-31 then the log file would be:  
```
/var/log/cfgbackup/alpha_20161231.log
```

If you run a job multiple time to the same log file, then the log entries will be
appended to it.

**Status Command**  
The `status` command will report the current status of the job in question. It will
report the type of job, whether it is running or failed, what the process id, and
more. It also reports the last few lines of the most recent log file.  
```
./cfgbackup alpha.conf status
```

**List Command**  
The `list` command is for rotation job only. It will list all backup rotation
subdirectories and their date.
```
./cfgbackup alpha.conf list
```

**Reset Command**  
The `reset` command will attempt to reset things to a state where you can run a new
job. If a job is running, it can attempt to kill the current job. If the previous
run had failed, then it will attempt to put things back into place in order to let
you start a new job.
```
./cfgbackup alpha.conf reset
```


Config Options
------------------------
`SOURCE_DIR` The directory to create backups from. Can be local or remote
via SSH.  
```
SOURCE_DIR=/home/
SOURCE_DIR=/var/data
SOURCE_DIR=backups@server.example.com:/path/to/files/
```

`TARGET_DIR` The directory to sync to (sync type), or where to create subdirectory
rotations (rotation type). Must be a local directory.  
```
TARGET_DIR=/var/snyc/
TARGET_DIR=/home/backups
```

`BACKUP_TYPE` The type of backup to make. Value must be either `sync` or `rotaion`.  
Sync jobs will make the `TARGET_DIR` exactly match the `SOURCE_DIR`, unless other
options prevent it (see `ALLOW_DELETIONS` and `ALLOW_OVERWRITES`).  
Rotation jobs will create a new subdirectory to contain each backup; once the
maximum number of backups is reached, it will rotate the last backup within
the `MAX_ROTATIONS` list of backups.  
```
BACKUPS_TYPE=sync
BACKUPS_TYPE=rotation
```

`NOTIFY_EMAIL` The email to send failures and notification to. If left blank,
then no emails will be sent. Setting this is highly recommened!  
```
NOTIFY_EMAIL=admin@example.com
NOTIFY_EMAIL=root@localhost
```

`LOG_DIR` The directory where log files will be saved. If left blank or missing,
then the value will default to `/var/log/cfgbackup/`.
```
LOG_DIR=/var/log
```

`LOG_FILENAME` The name of the log file to use for a job. There are three variables
you can use in the value:  
- `CONFNAME` The name of the config file minus the extension. e.g. 'active' for `active.conf`
- `DATE` The date when the job was started. e.g. `20161231`
- `TIME` The time when the job was started. e.g. `235959`
The default value is `CONFNAME_DATE.log`.  
```
LOG_FILENAME=backup_DATETIME.log
LOG_FILENAME=cfgb_CONFNAME.log
```

```
MAX_ROTATIONS=8
ROTATIONALS_HARD_LINK=0
IDENTICALS_HARD_LINK=0
COMPRESS_LOGS=1
ROTATE_SUBDIR=backup-NUM1
ALLOW_DELETIONS=1
ALLOW_OVERWRITES=1
RSYNC_FLAGS=
RSYNC_PATH=
MAIL_PATH=
PRE_SCRIPT=/path/to/prescript.sh
SUCCESS_SCRIPT=/path/to/successscript.sh
FAILED_SCRIPT=/path/to/failedscript.sh
FINAL_SCRIPT=/path/to/postscript.sh
RUNNING_DIRNAME=backup-running
PID_FILE=.cfgbackup.pid
SORT_PATH=
HARDLINK_PATH=
COMPRESS_PATH=gzip
```


More Details
------------------------
**Manually Reseting a Job**  
TODO  


