#!/bin/bash
# Repo list

# import
. git_login
. git_mirror

# repos
git_mirror boost svn http://svn.boost.org/svn/boost/trunk
git_mirror boost/release svn http://svn.boost.org/svn/boost/branches/release
git_mirror busybox git git://busybox.net/busybox.git
git_mirror calibre bzr lp:calibre
git_mirror chere git git://repo.or.cz/chere.git
git_mirror comical svn svn://svn.code.sf.net/p/comical/code/trunk
git_mirror conemu svn http://conemu-maximus5.googlecode.com/svn/trunk
git_mirror console-devel hg http://hg.code.sf.net/p/console-devel/code
git_mirror cygwin cvs :pserver:anoncvs@cygwin.com:/cvs/src src
git_mirror darwinbuild svn http://svn.macosforge.org/repository/darwinbuild/trunk
git_mirror dd-wrt svn svn://svn.dd-wrt.com/DD-WRT '--ignore-paths=^src/linux'
git_mirror deluge git git://deluge-torrent.org/deluge
git_mirror desmume svn https://svn.code.sf.net/p/desmume/code/trunk
git_mirror dmidecode cvs :pserver:anonymous:@cvs.savannah.gnu.org:/sources/dmidecode dmidecode
git_mirror dolphin-emu git https://code.google.com/p/dolphin-emu
git_mirror env-man git git://env-man.git.sourceforge.net/gitroot/env-man/env-man
git_mirror firmware-mod-kit svn http://firmware-mod-kit.googlecode.com/svn/trunk
git_mirror flashdevelop svn http://flashdevelop.googlecode.com/svn/trunk
git_mirror freedownload svn svn://svn.code.sf.net/p/freedownload/code/trunc
git_mirror grrlib svn http://grrlib.googlecode.com/svn/trunk
git_mirror hydrairc svn http://svn.hydrairc.com/hydrairc/trunk
git_mirror irssi git git://git.irssi.org/irssi
git_mirror jd_unofficial svn svn://svn.jdownloader.org/jdownloader/trunk
git_mirror jpcsp svn http://jpcsp.googlecode.com/svn/trunk
git_mirror launch4j cvs :pserver:anonymous@launch4j.cvs.sourceforge.net:/cvsroot/launch4j launch4j
git_mirror levelzap git https://git01.codeplex.com/levelzap
git_mirror libdvdread git git://git.videolan.org/libdvdread.git
git_mirror libdvdnav git git://git.videolan.org/libdvdnav.git
git_mirror libogc git git://devkitpro.git.sourceforge.net/gitroot/devkitpro/libogc
git_mirror libreoffice git git://anongit.freedesktop.org/libreoffice/core
git_mirror libtorrent svn https://svn.code.sf.net/p/libtorrent/code/trunk
git_mirror libX11 git git://anongit.freedesktop.org/xorg/lib/libX11
git_mirror libXi git git://anongit.freedesktop.org/xorg/lib/libXi
git_mirror listfix svn https://svn.code.sf.net/p/listfix/code/dev
git_mirror make git git://git.savannah.gnu.org/make
git_mirror mame svn svn://dspnet.fr/mame/trunk
git_mirror mingw-org-wsl git git://git.code.sf.net/p/mingw/mingw-org-wsl
git_mirror mingw-w64 svn https://svn.code.sf.net/p/mingw-w64/code '--ignore-paths=^(branches|stable|tags|web)'
git_mirror mintty svn http://mintty.googlecode.com/svn/trunk
git_mirror model3emu svn https://svn.code.sf.net/p/model3emu/code/trunk
git_mirror notepadplus svn svn://svn.tuxfamily.org/svnroot/notepadplus/repository/trunk
git_mirror nulldc svn http://nulldc.googlecode.com/svn/trunk
git_mirror obsproject git git://git.code.sf.net/p/obsproject/code
git_mirror odin svn https://svn.code.sf.net/p/odin-win/code/trunk
git_mirror openal-soft git git://repo.or.cz/openal-soft.git
git_mirror openoffice git git://git.apache.org/openoffice.git
git_mirror pagedown hg https://code.google.com/p/pagedown
git_mirror patch git git://git.savannah.gnu.org/patch.git
git_mirror pcsx2 svn http://pcsx2.googlecode.com/svn/trunk
git_mirror pcsxr svn https://pcsxr.svn.codeplex.com/svn/pcsxr
git_mirror plainamp svn svn://svn.code.sf.net/p/plainamp/code/trunk
git_mirror plibc svn https://svn.code.sf.net/p/plibc/code/trunk/plibc
git_mirror processhacker svn svn://svn.code.sf.net/p/processhacker/code
git_mirror qconf svn http://delta.affinix.com/svn/trunk/qconf
git_mirror qt git git://gitorious.org/qt/qt.git
git_mirror qtbase git git://gitorious.org/qt/qtbase.git
git_mirror rarfilesource git http://www.v12pwr.com/RARFileSource.git
git_mirror reactos svn svn://svn.reactos.org/reactos/trunk
git_mirror sed git git://git.savannah.gnu.org/sed.git
git_mirror smartmontools svn https://svn.code.sf.net/p/smartmontools/code/trunk/smartmontools
git_mirror soundtouch svn https://svn.code.sf.net/p/soundtouch/code/trunk
git_mirror superputty svn http://superputty.googlecode.com/svn/trunk
git_mirror vba cvs :pserver:anonymous@vba.cvs.sourceforge.net:/cvsroot/vba VisualBoyAdvance
git_mirror vba-rerecording svn http://vba-rerecording.googlecode.com/svn/trunk
git_mirror vbam svn https://svn.code.sf.net/p/vbam/code
git_mirror vbox svn http://www.virtualbox.org/svn/vbox/trunk
git_mirror virtualjaguar git http://shamusworld.gotdns.org/git/virtualjaguar
git_mirror VMsvga2 svn svn://svn.code.sf.net/p/vmsvga2/code/VMsvga2/trunk
git_mirror wget git git://git.sv.gnu.org/wget.git
git_mirror wiimms-iso-tools svn http://opensvn.wiimm.de/wii/branches/public/wiimms-iso-tools
git_mirror winscp cvs :pserver:anonymous:@winscp.cvs.sourceforge.net:/cvsroot/winscp winscp3
git_mirror xmlrpc-c svn http://svn.code.sf.net/p/xmlrpc-c/code '--ignore-paths=^(super_stable|userguide)'
git_mirror xmlstar git git://git.code.sf.net/p/xmlstar/code
git_mirror xserver git git://anongit.freedesktop.org/xorg/xserver
