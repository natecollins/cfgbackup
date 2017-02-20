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
- Rsync (3.1.0+ recommended)
- GNU Coreutils


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

# Name of file where logs should be saved to.
# Allowed variables of CONFNAME, DATE, TIME
LOG_FILENAME=CONFNAME_DATE.log

# Allow backups to delete files from target directory
# - If set to 0, any deleted files will be reported in logs and
#   email, but not removed from target dir
# - If set to 1, this sets the rsync flag: --del
ALLOW_DELETIONS=1

# Allow files to be overwritten in the target directory
# - If set to 0, any changed files will be reported in logs and
#   email, but will not change files in existing target dir
# - If set to 0, this sets the rsync flag: --ignore-existing
ALLOW_OVERWRITES=1

# Maximum number of backups to create if BACKUP_TYPE is rotation
# Ignored if BACKUP_TYPE is mirror
# When rotating old backups, the backup that is MAX_ROTATIONS old (by dir name)
# will be reused for the next backups, even if there are older backups present
MAX_ROTATIONS=8

# Hard link files that have not changed between rotation backups
ROTATIONALS_HARD_LINK=0

# Hard link identical files within a single backup
# This is a post-transfer process; all files will initally be copied to target dir
IDENTICALS_HARD_LINK=0

# Rotation only subdirectory name; requires rotation key of: NUM0, NUM1, or DATE
# backup_NUM0 = numeric increment starting with 0
# rotation-NUM1 = numeric increment starting with 1
# backup_DATE = year month day of when backup started
# The NUM keys can be zero padded, such as NUM00 or NUM0001
ROTATE_SUBDIR=backup-NUM1

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# advanced settings
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Additional flags to add to the rsync job.
# Standard rsync flags always used regardless: -av --stats
RSYNC_FLAGS=

# Specify full path to local rsync binary
# By deafult, the PATH will be searched
RSYNC_PATH=

# Specify full path to local mail binary
# By deafult, the PATH will be searched
MAIL_PATH=

# Pre-run script before backup. Pre-script must return 0 or
# backup will not be started.
PRE_SCRIPT=/path/to/prescript.sh

# Post-run script after successful backups only
SUCCESS_SCRIPT=/path/to/successscript.sh

# Post-run script after failed backups only
FAILED_SCRIPT=/path/to/failedscript.sh

# Post-run script after all backsup (after success/failed script)
FINAL_SCRIPT=/path/to/postscript.sh

# Rotation only - name of directory used for running or incomplete backups
RUNNING_DIRNAME=backup-running

# Name of PID file which will be present in the TARGET_DIR while a job is running
PID_FILE=.cfgbackup.pid


More Details
------------------------
**Manually Reseting a Job**  
TODO  


