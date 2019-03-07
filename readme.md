# bashpass

password generator, storage, reference for the terminal and/or X.

## Use case

  * I can create passwords
  *    //  recall passwords
  *    //  update passwords
  *    //  delete accounts
  *    //  import a csv file.

### <p align="center">[bash](bashpass.sh)</p>
<p align="center">Terminal only. (bashpass.sh -ui terminal)</p>
<p align="center"><a href="assets/bp.png"><img alt="bashpass" src="assets/bp.png"></a></p>

### <p align="center">[dialog](bashpass.sh)</p>
<p align="center">Without X using dialog. (bashpass.sh -ui dialog)</p>
<p align="center"><a href="assets/dp.png"><img alt="dialogpass" src="assets/dp.png"></a></p>

### <p align="center">[Xdialog](bashpass.sh)</p>
<p align="center">On X using Xdialog.</p>
<p align="center"><a href="assets/xp.png"><img alt="dialogpass" src="assets/xp.png"></a></p>

## Usage ```bashpass.sh [[some.db3]|[-db some.db3]] [-ui Xdialog|dialog|terminal]```

### First time only:

 * If you don't already have one, make a default [gpg2 keyring](https://www.gnupg.org/gph/en/manual/c14.html).

 * Make and encrypt a demo .db3 file.

   * The easy way: Run [first-use.sh](first-use.sh) from [bashpass.sh](bashpass.sh)'s directory.

   * The hard way: You'll need to build git.db3 like so: ```sqlite3 git.db3 < ac.sql``` and encrypt it like so: ```gpg2 --default-recipient-self --output git.db3.asc --encrypt git.db3```

    Reason being sqlite3 *.db3 files you'll work with, needs to be encrypted to your own keyring(/s).

    All relevant files must reside in [bashpass.sh](bashpass.sh)'s directory.

### Subsequent uses:

For subsequent uses just fire up the script directly: ```bashpass.sh git.db3``` from a terminal, or ```bashpass-launcher.sh git.db3``` from X, launcher application, DE hotkey, menu, etc.

### Optional command line arguments

If you'd like to test other UI options try: ```bashpass.sh [[some.db3]|[-db some.db3]] [-ui Xdialog|dialog|terminal]```

### NOTES

 1. You can only have one instance of [bashpass.sh](bashpass.sh) running at any given time for obvious reasons.

    Internally enforced by a simple MUTEX implementation.

 2. Consider launching [bashpass.sh](bashpass.sh) with launch from terminal option enabled (where available) and through [bashpass-launcher.sh](bashpass-launcher.sh) if no such option available. (DE hotkey for example).

    For SQLite session availability mainly but also for troubleshooting reason.

 3. Passwords generated by [bashpass.sh](bashpass.sh) are 64 character long ```[:graph:]``` type random strings from ```/dev/urandom``` with the exception of colons ```[=|=]```, single ```[='=]``` and double ```[="=]``` quotes used by sqlite3's internal field separator and bash string quoting system.

### Security concerns

This application takes for granted that you can secure the safety of your computer at least for the duration of its operation.

A potentially misplaced hard drive if examined by a file recovery tool could reveal unencrypted version of password database files (.db3).

### Workarounds

by shredding along with removing unencrypted .db3 files upon trapped exit signals.

## TODOS

 * [x] Encryption
 * [ ] ~~Clipboard~~ (more prerequisites - dependencies, eg: ```xclip```) just consult your manual for copy-paste functionality.
 * [x] Modularize UI usage depending on the environment.

   * [x] GUI's based on availability
   * [x] GUI/TUI based on X
