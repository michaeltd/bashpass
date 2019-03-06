# bashpass

password generator, storage, reference for the terminal and/or X.

## Use case

  * I can create passwords
  *    //  recall passwords
  *    //  update passwords
  *    //  delete accounts
  *    //  import a csv file.

### <p align="center">[bash](bashpass.sh)</p>
<p align="center">Terminal only</p>
<p align="center"><a href="assets/bp.png"><img alt="bashpass" src="assets/bp.png"></a></p>

### <p align="center">[dialog](bashpass.sh)</p>
<p align="center">Without X using dialog (unset DISPLAY to test).</p>
<p align="center"><a href="assets/dp.png"><img alt="dialogpass" src="assets/dp.png"></a></p>

### <p align="center">[Xdialog](bashpass.sh)</p>
<p align="center">On X using Xdialog.</p>
<p align="center"><a href="assets/xp.png"><img alt="dialogpass" src="assets/xp.png"></a></p>

## Usage

### First time use:

 1. Easy: Run [first_use.sh](first_use.sh) from [this](./) directory.
 2. Manual: You'll need to build git.db3 like so: ```sqlite3 git.db3 < ac.sql``` and encrypt it like so: ```gpg2 --encrypt --default-recipient-self --output git.db3.asc git.db3```

All relevant files must reside in [this](./) directory.

### Subsequent uses:

For subsequent uses just fire up the script directly: ```bashpass.sh git.db3```

### NOTE

You can only have one instance of [bashpass.sh](bashpass.sh) running at any given time.

### Security concern

A potentially misplaced driver if examined by a file recovery tool could reveal unencrypted version of password database files (.db3).

### Workaround

shred instead of rm unencrypted .db3 files upon trapped exit signals.

## TODOS

 * [x] Encryption
 * [ ] ~~Clipboard~~
 * [x] Modularize UI usage depending on the environment.

   * [x] GUI's based on availability
   * [x] GUI/TUI based on X
