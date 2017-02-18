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



Config Options
------------------------


More Details
------------------------



