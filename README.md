cfgbackup - Simple File Backups
========================================
An easy to use file backup script where each job is based around a simple config file.  
- Does rotational backups or simple syncing
- Detailed logging
- Email notifications on failure
- Backups are simply files in directories, no special tools for recovery
- Can hard link unchanged files between rotational backups
- Can hard link identical files with a single backup
- Very customizable


Quick Links
------------------------
* [Dependencies](#dependencies)
* [Basic Usage](#basic-usage)
* [Commands](#commands)
* [Config Options](#config-options)
* [Automating Backups via Cron](#automating-backups-via-cron)
* [More Information](#more-information)
* [Special Circumstances](#special-circumstances)
* [Author and License](#author-and-license)


Dependencies
------------------------
- bash 4.2+
- rsync (recommended 3.1.0+)
- awk
- sed
- coreutils
- findutils
- hardlink (recommended)


Installation
------------------------
Installation can be as simple as downloading the `cfgbackup` script, setting the execute flag, and placing it in a logical
place, like `/usr/local/bin/`. You'll likely want to grab a copy of the `example.conf` file as well, to use as a template
for creating backup jobs.  

For Debian based Linux distributions, you can use the `build/build-deb` script to create a `.deb` package, then install
that with `dpkg` like any other package.  


Basic Usage
------------------------
There are two basic types of backup jobs `cfgbackup` can do: `rotation` and `sync`  
 - `rotation` jobs create a series of backup rotations in subdirs of the target dir
 - `sync` jobs syncronize a directory from one location to another

Each backup job has it's own config file. Provided is an sample config called `example.conf`;
recommended is that you copy this file to use as a template, modifying it as you like. The
file can reside anywhere, but suggested location for your config files in production
is `/etc/cfgbackup/`.  

In this file, you will need to specify a few required config options.  
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


Commands
------------------------
- [`check`](#command-check)
- [`run`](#command-run)
- [`status`](#command-status)
- [`list`](#command-list)
- [`reset`](#command-reset)


<a name="command-check"></a>
**Check Command**  
The `check` command will parse the config, checking for errors.  
```
./cfgbackup alpha.conf check
```

If something wrong is detected in the config file, a message will display describing the error.  

If no problems are detected, it will respond with `Config is OK.`.  

<a name="command-run"></a>
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

<a name="command-status"></a>
**Status Command**  
The `status` command will report the current status of the job in question. It will
report the type of job, whether it is running or failed, what the process id, and
more. It also reports the last few lines of the most recent log file.  
```
./cfgbackup alpha.conf status
```

<a name="command-list"></a>
**List Command**  
The `list` command is for rotation job only. It will list all backup rotation
subdirectories and their date.
```
./cfgbackup alpha.conf list
```

<a name="command-reset"></a>
**Reset Command**  
The `reset` command will attempt to reset things to a state where you can run a new
job. If a job is running, it can attempt to kill the current job. If the previous
run had failed, then it will attempt to put things back into place in order to let
you start a new job.
```
./cfgbackup alpha.conf reset
```

Note: When running reset on a job with DATE based subdirectories, the command will
reset the folder to a date just older than the oldest backup directory, not
necessarily the date it was before running the job.  


Config Options
------------------------
- [`SOURCE_DIR`](#source-dir)
- [`TARGET_DIR`](#target-dir)
- [`BACKUP_TYPE`](#backup-type)
- [`NOTIFY_EMAIL`](#notify-email)
- [`LOG_DIR`](#log-dir)
- [`LOG_FILENAME`](#log-filename)
- [`COMPRESS_LOGS`](#compress-logs)
- [`MAX_ROTATIONS`](#max-rotations)
- [`ROTATIONALS_HARD_LINK`](#rotationals-hard-link)
- [`IDENTICALS_HARD_LINK`](#identicals-hard-link)
- [`ROTATE_SUBDIR`](#rotate_subdir)
- [`ALLOW_DELETIONS`](#allow-deletions)
- [`ALLOW_OVERWRITES`](#allow-overwrites)
- [`RSYNC_FLAGS`](#rsync-flags)
- [`PRE_SCRIPT`,`SUCCESS_SCRIPT`,`FAILED_SCRIPT`,`FINAL_SCRIPT`](#script-options)
- [`PRE_SCRIPT_ERROR_EXIT`](#pre-script-error-exit)
- [`RUNNING_DIRNAME`](#running-dirname)
- [`PID_FILE`](#pid-file)
- [`RSYNC_PATH`,`COMPRESS_PATH`,`HARDLINK_PATH`,`MAIL_PATH`,`SORT_PATH`](#path-options)

<a name="source-dir"></a>
`SOURCE_DIR` The directory to create backups from. Can be local or remote
via SSH.  
[Required]  
```
SOURCE_DIR=/home/
SOURCE_DIR=/var/data
SOURCE_DIR=backups@server.example.com:/path/to/files/
```

<a name="target-dir"></a>
`TARGET_DIR` The directory to sync to (sync type), or where to create subdirectory
rotations (rotation type). Must be a local directory.  
[Required]  
```
TARGET_DIR=/var/snyc/
TARGET_DIR=/home/backups
```

<a name="backup-type"></a>
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

<a name="notify-email"></a>
`NOTIFY_EMAIL` The email to send failures and notification to. If left blank,
then no emails will be sent. Setting this is highly recommened!  
[Deafult value is ` ` (blank)]  
```
NOTIFY_EMAIL=admin@example.com
NOTIFY_EMAIL=root@localhost
```

<a name="log-dir"></a>
`LOG_DIR` The directory where log files will be saved.  
[The default value is `/var/log/cfgbackup/`]  
```
LOG_DIR=/var/log
```

<a name="log-filename"></a>
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

<a name="compress-logs"></a>
`COMPRESS_LOGS` The logs generated by cfgbackup are very verbose and can grow quite large.
Thankfully, they are also very compressible. By enabling this option, cfgbackup will check for
old logs (over 2 days old) that match the `LOG_FILENAME` pattern for this job and compress them.
By default, it will use gzip, but this can be changed with the `COMPRESS_PATH` options. To enable
compression, set this option to 1, all other values will disable compressed logs.  
[Default value is `1`]  
```
COMPRESS_LOGS=1
```

<a name="max-rotations"></a>
`MAX_ROTATIONS` Only applies to `rotation` value of `BACKUP_TYPE`, this is the maximum number
of rotational backups for cfgbackup to make. Note that you should probably want to set this
number to 1 higher than the maxumim usable backups you'll want. As 1 backup might be in
transition while the job is running. So to guarantee 14 backups always be available, you'll
want to set this to be at least 15.  
[Required for 'rotation' jobs, ignored otherwise]  
```
MAX_ROTATIONS=15
```

<a name="rotationals-hard-link"></a>
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

<a name="identicals-hard-link"></a>
`IDENTICALS_HARD_LINK` When enabled, searches for files with identical content within a single run
of a backup job and hard link them together. Files that are hard linked together point to the same
location on disk, so they don't take up extra space. This particular option requires the `hardlink`
program is available; if `hardlink` is not found, setting this option will prevent the job from running.
Note that running `hardlink` runs as a separate process after the rsync process has completed, thus
adding extra time to how long a job takes to run. With large backups, this can potentially take a very
long time. Enabled if set to `1`, disabled otherwise.  
[Default value of `0`]  
```
IDENTICALS_HARD_LINK=1
```

<a name="rotate_subdir"></a>
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

<a name="allow-deletions"></a>
`ALLOW_DELETIONS` With this option set to `1`, files may be deleted from the target backup directory if they
are missing from the source directory. If set to `0`, then no file deletions will happen in the target directory;
additionally, the list of files that do not exist in the source directory will be logged and emailed to
the value of `NOTIFY_EMAIL`.  
With a value of `1`, this adds the `--del` flag to the rsync command.  
[Default value of `1`]  
```
ALLOW_DELETIONS=0
```

<a name="allow-overwrites"></a>
`ALLOW_OVERWRITES` With this option set to `1`, files may be updated/overwritten in the target backup directory if
then differ in the source directory. If set to `0`, then no file modifications will happen in the target directory;
additionally, the list of files that are different in the source directory will be logged and emailed to
the value of `NOTIFY_EMAIL`.  
With a value of `0`, this adds the `--ignore-existing` flag to the rsync command.  
[Default value of `1`]   
```
ALLOW_OVERWRITES=0
```

<a name="rsync-flags"></a>
`RSYNC_FLAGS` For any additional custom flag you would like passed directy to rsync. Note this only adds additional
flags, however, you can use the `--no-OPTION` flags to negate implied flags. For example, you can pass the
`--no-p` flag to not have rsync syncronize permissions. See the rsync manual for details: `man rsync`  
Flags always included, even when none are specified: `-av --stats`  
```
RSYNC_FLAGS=--exclude=.DS_Store --exclude=._*
```

<a name="script-options"></a>
`PRE_SCRIPT`,`SUCCESS_SCRIPT`,`FAILED_SCRIPT`,`FINAL_SCRIPT` All these script options allow for the setting
of a script to run at a specific time during a backup job run. What you enter will be evaluated as a shell command,
so placing multiple commands together and using pipes will also work.  
 - `PRE_SCRIPT` This script will be run immediately when the backup job starts (but after config if checked/parsed), before any other run actions.
 - `SUCCESS_SCRIPT` Runs this script after the backup job has completed if rsync returns an exit code of 0; also waits until after hardlinks are created if `IDENTICALS_HARD_LINK` is set to 1.
 - `FAILED_SCRIPT` Runs this script immediate after rsync if rsync returns an exit code other than 0.
 - `FINAL_SCRIPT` This script runs as the last thing before the cfgbackup run job ends, regardless of success or failure of rsync.
Any scripts specified will cause the backup job to send a failure email if they return a non 0 exit code.  
```
PRE_SCRIPT=/usr/local/bin/app-cache --clear
SUCCESS_SCRIPT=service myapp restart; service apache2 restart
FAILED_SCRIPT=/usr/local/bin/dump-app-state
FINAL_SCRIPT=~adminguy/gen-server-report
```

<a name="pre-script-error-exit"></a>
`PRE_SCRIPT_ERROR_EXIT` If set to 1, this will require the `PRE_SCRIPT` to have an exit code of 0,
otherwise the backup job will send a failure notification and then immediately exit.  
[Default value of `0`]  
```
PRE_SCRIPT_ERROR_EXIT=1
```

<a name="running-dirname"></a>
`RUNNING_DIRNAME` Only applied to to `rotation` type jobs, this option sets the name of the
subdirectory used when running an active backup job. This should be unique and never conflict with the
directory names generated by `ROTATE_SUBDIR`.  
[Default value of `backup-running`]  
```
RUNNING_DIRNAME=backup_in_progress
```

<a name="pid-file"></a>
`PID_FILE` This is a file that is created in the `TARGET_DIR` whenever a backup job is run. Once the job
completes, the file is deleted. The file contains the process id of the main cfgbackup process. For jobs
of type `sync` this file will be ignored as cfgbackup will automatically add the rsync
flag `--exclude=/PID_FILE` to the job.  
[Default value of `.cfgbackup.pid`]  
```
PID_FILE=.cfgbackup.pid
```

<a name="path-options"></a>
`RSYNC_PATH`,`COMPRESS_PATH`,`HARDLINK_PATH`,`MAIL_PATH`,`SORT_PATH` The path options allow you to override
the binaries for various programs used by cfgbackup. For `COMPRESS_PATH` you can change the type of compression
used by switching the binary.
```
RSYNC_PATH=/usr/local/bin/rsync
COMPRESS_PATH=bzip2
HARDLINK_PATH=/usr/local/bin/hardlink
MAIL_PATH=/usr/local/bin/mailx
SORT_PATH=/usr/local/bin/gsort
```


Automating Backups via Cron
------------------------
The recommended way of automating backup jobs is via cron. For those unfamiliar with cron, it provides a
way to schedule commands to run at regular intervals. Cron tasks can be entered in a
system-wide file, `/etc/crontab`, or on a per-user basis with the `crontab` command. The word "crontab" is
short for "cron table", which means a text file with tablular contents to list commands to run at certain times.
Using the system-wide crontab is a good idea for backup jobs on multi-user systems, like servers, so that
other users are aware of the backup job without having to check other peoples personal crontab.  

**System Crontab (Recommended)**  
Example crontab entries for `/etc/crontab`:
```
# m  h  dom mon dow  user       command
 30  9  *   *   *    gerald     /usr/local/scripts/report_for_gerald.sh

# webspace hourly backups; runs every hour at 5 minutes into the hour
 5   *  *   *   *    root       cfgbackup /etc/cfgbackup/webspace_hourly.conf run

# webspace hourly backups: runs every day at 11:30pm
 30  23 *   *   *    root       cfgbackup /etc/cfgbackup/webspace_daily.conf run
```

As you'll notice, each line is broken up into columns, with each column delimited by spaces or tabs. The columns
do not have to line up horizontally, but it's a good idea to do so if you want to keep your crontab file readable.
To keep track of tasks, it's a good idea to also add a comment about your entries describing what it does. Comments
are created using the `#` character; anything after a `#` is considered a command and ignored by cron.  

The columns in crontab are, in order:  
 - `m` The minute of the hour on which to run, or `*` to run every minute
 - `h` The hour of the day (from `0` to `23`) on which to run, or `*` to run every hour
 - `dom` The day of the month on which to run, or `*` to run every day
 - `mon` The month of the year on which to run, or `*` to run every month
 - `dow` The day of the week on which to run, or `*` to run every day
 - `user` Run the command as if this user running it
 - `command` The command to run

**Personal Crontab**  
If you don't have access to the `/etc/crontab` file, you can use the `crontab` command to load or edit a crontab
file for your user. The format is almost exactly the same as `/etc/crontab` except there is no `user` column. All
commands started from a user's crontab are always run by that user's account.  

Example crontab entries for a user's crontab:  
```
# m  h  dom mon dow  command
 30  8  *   *   *    /home/gerald/scripts/morning_schedule.sh
 0   13 *   *   *    /home/gerald/scripts/afternoon_schedule.sh

# document directory rotation
 45  *  *   *   *    cfgbackup /home/gerald/cfgbackup/documents_rotate.conf run
```

To edit a user crontab file in-place, run `crontab -e`; this will allow you to edit the file in a terminal
text editor.  

If you already have a crontab written in another file, you can load it into your crontab by
just passing it to the `crontab` command:  
```
crontab load_file.txt
```


More Information
------------------------
**Backups should be remote and inaccessible**  
Backups should never reside on the same machine where the original files exist. Any "backups" that
exist on the origin machine's disk are completely worthless if the RAID fails, file-system become
corrupted, rack catches on file, etc.  

Additionally, backups that are accessible by the origin machine aren't very helpful when put up
against malicious actors. Any hacker/disgruntled employee who has access to the original data
may attempt to sully the backups as well.  

Either setup and use a remote Public Key SSH connection to grab the source files from the origin
machine, or have the source machine push a single copy of its data to a remote location, and then
have the backup job pull a rotation from there.  

**Be Careful with Hard Links**  
Hard linking files is great for reducing the disk spaces used; you can have dozens of files hard linked
together and the data for all those files will take up the same disk space as the data for a single
copy. This because they all point to the same location on disk.  

If you are hard linking files between rotationals (via `ROTATIONALS_HARD_LINK`), you need to be aware
that you should never edit/modify a hard linked file in one backup, as it will result in ALL hard linked
copies being edited.  

If you are hard linking identical files within a backup (via `IDENTICALS_HARD_LINK`), all those files
will have end up with the same timestamps, ownership, and permissions. While this is not an concern when
when dealing with rotation hard links, when you hard link files within the same backup, you may be
discarding some useful metadata. If only the content of the files is relevant to you, then this will be
of no concern. However, if timestamps, ownership, or file permissions are important, then you may not
want to enable `IDENTICALS_HARD_LINKS`.  

**Manually Reseting a Job**  
While the simplest way to fix a failed/dead job is to use the `reset` command, you can also manually
reset a job. To reset a job:  
 - Ensure the main cfgbackup process and any child processes are killed
 - Remove the `PID_FILE` from the `TARGET_DIR`
 - For rotationals, rename the `RUNNING_DIRNAME` back to be the oldest backup subdir of your `MAX_ROTATIONS`


Special Circumstances
------------------------
Following are a number of situations and how you could solve them. A large number
of problems can be solved via use the the `RSYNC_FLAGS` option, as rsync is quite
powerful.  

**SSH on non-standard port**  
To change which SSH port rsync will use, you must manually set the remote shell using
the `-e` flag. For example, to set SSH to use port 345, you would need the following:  
```
RSYNC_FLAGS=-e "ssh -p 345"
```

**Backing up source directories that already contain hard links**  
This one is quite simple. The rsync program supports syncing hard links,
but disables it by default due to the performance hit it takes to track them.  

To backup hard links, all you need to do is add the `-H` flag to the
`RSYNC_FLAGS` option.
```
RSYNC_FLAGS=-H
```

**Limit backup bandwidth used**  
To limit the maximum bandwidth that can be used by the backup job when the
source is coming over SSH, you can use the rsync flag `--bwlimit`. See the
rsync manual for more info: `man rsync`  
```
RSYNC_FLAGS=--bwlimit=10M
```

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

**Only allow new files; no changes/deletions**  
To prevent file changes and deletions, and then have cfgbackup email you a report of prevented
changes/deletions to `NOTIFY_EMAIL`, just set the following two options:
```
ALLOW_DELETIONS=0
ALLOW_OVERWRITES=0
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

Once setup, install the required packages using the method appropriate to the
package management you selected. You will likely need to specify all the paths
to the tools you installed as options in the config file.  

Once installed, you may need to specify the path to newer binaries. Examples:  
```
# Homebrew example paths
RSYNC_PATH=/usr/local/bin/rsync
SORT_PATH=/usr/local/bin/gsort
# Macports example paths
RSYNC_PATH=/opt/local/bin/rsync
SORT_PATH=/opt/local/bin/sync
# Fink example paths
RSYNC_PATH=/sw/bin/rsync
SORT_PATH=/sw/bin/sort
```

**Running on a Windows**  
You _should_ be able to run cfgbackup without any problems using either Cygwin or
Windows Subsystem for Linux (aka Ubuntu on Windows), as long as you install the required
dependencies. However, this functionality has not been tested.  


Author and License
------------------------
Copyright (c) 2017 by Nathan Collins [npcollins@ gmail.com]  

Released under the MIT License

