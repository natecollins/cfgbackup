CFGBACKUP - Simple File Backups
========================================
An easy to use backup script where each job is based around a config file.  
 - Very few dependencies - only standard open source tools, like Bash and rsync
 - Does rotational backups or simple syncing
 - Reduce disk usage by hard linking unchanged files between rotationals
 - Email notifications on failure
 - Optional notification on file change/delete attempts
 - Pull backup source remotely over SSH
 - Customizable rotational directory names
 - And much more!

* [Requirements](#requirements)

Requirements
------------------------
- Bash Shell 4.3+
- Rsync 3.1.0+ (recommended)
- GNU Coreutils


