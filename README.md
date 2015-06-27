# back2attic

This is a wrapper to create relatively safe backups (esp. for **MySQL**) by locking tables and using a **LVM snapshot**. 

The backup software it was created for is **[Attic](https://attic-backup.org/index.html)** together with a remote **SSH based repository**. The data in the remote can easily be AES encrypted. You can copy the corresponding key to other machines to access/extract backup-data there.

This setup can run regularly (like every hour) without using many resources even for **multiple GB** of data in you database. 

Actually the software could be used with any other backup method. 

We put this online to show how something like this can be done easily with **[Nim](http://nim-lang.org)** instead of using a scripting language!

Compile with: `nim c back2attic.nim`

Usage: `back2attic <your-backupscript>`

An example backup-script for attic is included in the src folder. You can change this to anything else you like (duplicity / rsync / mysqldump with a temporary mysql server on the snapshot files). 

The given backup-script is called after the LVM snapshot was created and mounted. We handle CTRL+C and other errors by removing the mounted volume and LVM snapshot before returning to the shell.

You need:

* [Nim](http://nim-lang.org) programming language
* [Attic](https://attic-backup.org/index.html) de-duplicating backup
* Something you want to backup which resides on LVM devices using MySQL (MyISAM)
* Some remote Server with SSH access as target for the backups

> Disclaimer: We do not want to provide an universal solution. There is no configuration and you need to read up the docs for all components yourself! We provide this free of charge with no support. It may be buggy, wrong, format your hard-drive or make you lose data.

Copyright METATEXX GmbH - MIT License