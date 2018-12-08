# <p align="center">bashpass</p>

  password generator, storage, reference for the terminal.

## <p align="center">Use case</p>

  * I can create passwords
  *    //  recall passwords
  *    //  update passwords
  *    //  delete accounts
  *    //  import a csv file.

### <p align="center">[bashpass.sh](bashpass.sh)</p>
<p align="center"><a href="assets/bp.png"><img alt="bashpass" src="assets/bp.png"></a></p>
Terminal only

### <p align="center">[dialogpass.sh](dialogpass.sh)</p>
<p align="center"><a href="assets/dp.png"><img alt="dialogpass" src="assets/dp.png"></a></p>
Without X using dialog (unset DISPLAY to test).

### <p align="center">[dialogpass.sh](dialogpass.sh)</p>
<p align="center"><a href="assets/xp.png"><img alt="dialogpass" src="assets/xp.png"></a></p>
On X using Xdialog.

### <p align="center">[zenitypass.sh](zenitypass.sh)</p>
<p align="center"><a href="assets/zp.png"><img alt="zenitypass" src="assets/zp.png"></a></p>
Using [zenity](https://help.gnome.org/users/zenity)

## <p align="center">TODOS</p>

 * [ ] Encryption
 * [ ] Clipboard
 * [x] Modularize UI usage depending on the environment.

   * [x] GUI's based on availability
   * [x] GUI/TUI based on X
