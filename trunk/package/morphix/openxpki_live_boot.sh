#!/bin/sh
#echo 'firefox http://openxpkilive &' > /etc/X11/Xsession.d/60firefox_localhost
# set desktop background image
update-alternatives --install /etc/alternatives/desktop-background desktop-background /morphix/background.png 1
update-alternatives --set desktop-background /morphix/background.png
ln -s /etc/alternatives/desktop-background /usr/share/images/desktop-base/desktop-background
# kill networking
#rm /etc/rcS.d/S39ifupdown
#rm /etc/rcS.d/S40networking
# install tools
cp $1/morphix/files/openxpki_live_persist.sh /usr/sbin
chmod 755 /usr/sbin/openxpki_live_persist.sh
# update webpages
cp $1/morphix/files/livecd_index.html /var/www/index.htm
cp $1/morphix/files/livecd_persist.html /var/www/persist.htm
rm /var/www/index.html
# FIXME - does not seem to work
echo 'pref("browser.startup.homepage", "http://localhost/");'  >> /etc/iceweasel/pref/iceweasel.js 
# hide xfce tips
mkdir -p ~openxpkilive/.config/autostart
(echo '[Desktop Entry]'; echo 'Hidden=true') > ~openxpkilive/.config/autostart/xfce4-tips-autostart.desktop
/etc/init.d/apache start
# copy index from drive/USB if present
LOCALINDEX=$(find /mnt -maxdepth 2 -name 'openxpki_live_index.html' 2>/dev/null|head -1)
if [ "$LOCALINDEX" != "" ]; then
    cp $LOCALINDEX /var/www/index.htm
fi
MOUNTPOINT=$(find /mnt -maxdepth 2 -name 'openxpki_live.ext2' 2>/dev/null|head -1)
MOUNTPOINT=$(dirname $MOUNTPOINT)
if [ "$MOUNTPOINT" == "" ]; then
    echo "No OpenXPKI live persistent image found, using temporary CA for testing only"
    exit 1
fi
echo "Found image at $MOUNTPOINT, relinking OpenXPKI configuration and MySQL databases"
/etc/init.d/openxpkid stop
/etc/init.d/mysql stop
losetup /dev/loop0 ${MOUNTPOINT}/openxpki_live.ext2
mkdir /mnt/loop
mount /dev/loop0 /mnt/loop
echo 'umount /mnt/loop; losetup -d /dev/loop0' > /etc/rc0.d/S15local
chmod 755 /etc/rc0.d/S15local
# copy config and MySQL database to image, create symbolic links
rm -rf /var/lib/mysql
ln -s /mnt/loop/openxpki_live/var/lib/mysql /var/lib/mysql
rm -rf /etc/openxpki
ln -s /mnt/loop/openxpki_live/etc/openxpki /etc/openxpki
rm -rf /etc/mysql
ln -s /mnt/loop/openxpki_live/etc/mysql /etc/mysql
/etc/init.d/mysql start
/etc/init.d/openxpkid start
echo 'Listen 127.0.0.1:80' >> /etc/apache/httpd.conf
/etc/init.d/apache stop
/etc/init.d/apache start
if [ -x /mnt/loop/boot.sh ]; then
    /mnt/loop/boot.sh
fi