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
[Required]  
```
SOURCE_DIR=/home/
SOURCE_DIR=/var/data
SOURCE_DIR=backups@server.example.com:/path/to/files/
```

`TARGET_DIR` The directory to sync to (sync type), or where to create subdirectory
rotations (rotation type). Must be a local directory.  
[Required]  
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
[Required]  
```
BACKUPS_TYPE=sync
BACKUPS_TYPE=rotation
```

`NOTIFY_EMAIL` The email to send failures and notification to. If left blank,
then no emails will be sent. Setting this is highly recommened!  
[Deafult value is `` (blank)]  
```
NOTIFY_EMAIL=admin@example.com
NOTIFY_EMAIL=root@localhost
```

`LOG_DIR` The directory where log files will be saved.  
[The default value is `/var/log/cfgbackup/`]  
```
LOG_DIR=/var/log
```

`LOG_FILENAME` The name of the log file to use for a job. There are three variables
you can use in the value:  
- `CONFNAME` The name of the config file minus the extension. e.g. 'active' for `active.conf`
- `DATE` The date when the job was started. e.g. `20161231`
- `TIME` The time when the job was started. e.g. `235959`
[Default value is `CONFNAME_DATE.log`]  
```
LOG_FILENAME=backup_DATETIME.log
LOG_FILENAME=cfgb_CONFNAME.log
```

`COMPRESS_LOGS` The logs generated by cfgbackup are very verbose and can grow quite large.
Thankfully, they are also very compressible. By enabling this option, cfgbackup will check for
old logs (over 2 days old) that match the `LOG_FILENAME` pattern for this job and compress them.
By default, it will use gzip, but this can be changed with the `COMPRESS_PATH` options. To enable
compression, set this option to 1, all other values will disable compressed logs.  
[Default value is `1`]  
```
COMPRESS_LOGS=1
```

`MAX_ROTATIONS` Only applies to `rotation` value of `BACKUP_TYPE`, this is the maximum number
of rotational backups for cfgbackup to make. Note that you should probably want to set this
number to 1 higher than the maxumim usable backups you'll want. As 1 backup might be in
transition while the job is running. So to guarantee 14 backups always be available, you'll
want to set this to be at least 15.  
[Required for 'rotation' jobs, ignored otherwise]  
```
MAX_ROTATIONS=15
```

`ROTATIONALS_HARD_LINK` Only applies to `rotation` type jobs, if this value is set
to 1, then any unchanged files between rotation backups will be hard linked together. Files that
are hard linked together point to the same location on disk, so they don't take up extra space.
This can significantly reduce the amount of disk space a set of rotational backup occupies if not
many files actually change between jobs. It is recommended that you have rsync version 3.1.0 or
greater when this is enabled for best performance. If you have an older version of rsync, however,
then cfgbackup will perform the hard linking instead. Enabled if set to `1`, disabled otherwise.  
[Default value of `0`]
```
ROTATIONALS_HARD_LINK=1
```

`IDENTICALS_HARD_LINK` When enabled, searches for files with identical content within a single run
of a backup job and hard link them together. Files that are hard linked together point to the same
location on disk, so they don't take up extra space. This particular option requires the `hardlink`
program is available; if `hardlink` is not found, then this step of a backup job will be skipped.
Note that running `hardlink` runs as a separate process after the rsync process has completed, thus
adding extra time to how long a job takes to run. Enabled if set to `1`, disabled otherwise.  
[Default value of `0`]  
```
IDENTICALS_HARD_LINK=1
```

`ROTATE_SUBDIR` Only applied to to `rotation` type jobs, this option sets the name of the
subdirectories where the backed up files will be stored. The value must contain one rotation
key. Valid rotation keys are:  
 - `DATE` will result in an 8-digit date, such as `20001231`; multiple jobs per day will append a `.1`, `.2`, etc
 - `NUM0` will result in a numeric increment starting from 0 
 - `NUM1` will result in a numeric increment starting from 1
 - Left padded versions of the above NUM keys, such as `NUM01`, `NUM000`, `NUM0001`
[Default value of `backup-NUM1`]  
```
ROTATE_SUBDIR=backup-DATE
ROTATE_SUBDIR=bak_NUM01
```

```
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
**Be Careful with Hard Links**  
TODO

**Manually Reseting a Job**  
TODO  


Example Configs
------------------------
Following are a number of situations and how you could solve them. A large number
of problems can be solved via use the the `RSYNC_FLAGS` option, as rsync is quite
powerful.  

**Only allow new files; no changes/deletions**  
TODO

**SSH on non-standard port**  
TODO

**Backing up source directories that already contain hard links**  
This one is quite simple. The rsync program supports syncing hard links,
but disables it by default due to the performance hit it takes to track them.  

To backup hard links, all you need to do is add the `-H` flag to the
`RSYNC_FLAGS` option.
```
RSYNC_FLAGS=-H
```

**Limit backup bandwidth used**  
TODO

**Stuck backups - job running but no files transfering**  
Just because you don't see files transfering doesn't mean there is a problem.
The biggest benefit of rsync is that it only transfers files that need to be
updated. If no files needs to be changed, then you won't see anything writing
to the logs.  

That said, if you truely are experiencing a lost/stuck connection, you can tell
rsync to fail if no data is transfered after a given time. By setting the
`--timeout` flag under `RSYNC_OPTIONS`, you can set a maximum time in seconds
to wait for I/O to happen.  
```
RSYNC_FLAGS=--timeout=3600
```

**Running on a Mac**  
Unfortunately, Apple ships their OS with _very_ old version of some open
source software installed.
Fortunately, there are various other providers of open source software
packages you can use. Each handles package management slightly differently
but all can get the job done.  
  - Homebrew: `https://brew.sh/` Well polished and very popular amongst developers; targets individual user functionality rather than system wide use.
  - MacPorts: `https://www.macports.org/` Similarities to BSD ports package manager.
  - Fink: `http://www.finkproject.org/` Similarities to Debian apt package manager.

TODO  

