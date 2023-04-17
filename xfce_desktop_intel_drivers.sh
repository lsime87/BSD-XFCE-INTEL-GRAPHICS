#!/bin/bash
#xfce_desktop by Wamphyre (Somekind of FreeBSD Studio and Workstation)
#Version 2.0

test $? -eq 0 || exit 1 "NEED TO BE ROOT TO RUN THIS"

echo "Welcome to BSD-XFCE base script"
echo "This will install a complete, secure and optimized XFCE desktop in your FreeBSD system"
echo "WARNING!! - Execute only in a fresh vanilla installation"
sleep 5

## CHANGE FreeBSD REPOS TO LATEST
sed -i '' 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

## REBUILD AND UPDATE PKG DATABASE 
echo "Upgrading packages..."
echo ""
pkg update && pkg upgrade -y
echo ""

## FETCH FreeBSD PORTS
echo "Downloading Ports tree...";
echo ""
portsnap fetch auto
echo ""

## COMPILE CPU OPTIMIZED APPLICATIONS
## Please, change MAKE_JOBS_NUMBER?=16 by your needed CPU cores
touch /etc/make.conf
echo "CPUTYPE?=native" >> /etc/make.conf
echo "MAKE_JOBS_NUMBER?=16" >> /etc/make.conf
echo "OPTIONS_SET=OPTIMIZED_CFLAGS CPUFLAGS" >> /etc/make.conf

## INSTALLS BASE DESKTOP AND CORE UTILS
echo "Installing XFCE..."
echo ""
pkg install -y nano sudo bash wget htop xorg slim xfce xfce4-pulseaudio-plugin thunar-archive-plugin xarchiver unzip 
pkg install -y gnome-keyring xfce4-screenshooter-plugin shotwell atril-lite gnome-font-viewer mixer mixertui vlc qjackctl  
pkg install -y baobab networkmgr v4l-utils v4l_compat webcamd pwcview sctd brut clamtk filezilla vscode firefox deadbeef

## ENABLES BASIC SYSTEM SERVICES
echo "Enabling basic services"
sysrc moused_enable="YES"
sysrc dbus_enable="YES"
sysrc slim_enable="YES"
sysrc update_motd="NO"
sysrc rc_startmsgs="NO"
echo ""

## CREATES .xinitrc SCRIPT FOR A REGULAR DESKTOP USER
cd
touch .xinitrc
echo 'exec xfce4-session' >> .xinitrc
echo ""
echo ; read -p "Want to enable XFCE for a regular user? (yes/no): " X;
echo ""
if [ "$X" = "yes" ]
then
    echo ; read -p "For what user? " user;
    touch /usr/home/$user/.xinitrc
    echo 'exec xfce4-session' >> /usr/home/$user/.xinitrc
    echo ""
    echo "$user enabled"
else fi

## SPECIAL PERMISSIONS FOR USB DRIVES AND WEBCAM
echo "perm    /dev/da0        0666" >> /etc/devfs.conf
echo "perm    /dev/da1        0666" >> /etc/devfs.conf
echo "perm    /dev/da2        0666" >> /etc/devfs.conf
echo "perm    /dev/da3        0666" >> /etc/devfs.conf
echo "perm    /dev/video0     0666" >> /etc/devfs.conf
echo "" 

## ADDS USER TO CORE GROUPS
echo "Adding $user to video/realtime/wheel/operator groups"
pw usermod $user -G video
pw usermod $user -G realtime
pw usermod $user -G wheel
pw usermod $user -G operator
pw usermod $user -G network
pw usermod $user -G webcamd
echo ""

## ADDS USER TO SUDOERS
echo "Adding $user to sudo"
echo "$user ALL=(ALL:ALL) ALL" >> /usr/local/etc/sudoers
echo ""

## ENABLES LINUX COMPAT LAYER
echo "Enabling Linux compat layer..."
echo ""
kldload linux.ko
sysrc linux_enable="YES"
echo ""

## INSTALL LATEST INTEL DRIVERS FOR INTEGRATED CARDS (INTEL HD)
echo "Installing Intel drivers..."
echo ""
cd /usr/ports/graphics/drm-kmod
pkg install drm-kmod
cd /usr/ports/graphics/mesa-libs/
pkg install mesa-libs
cd /usr/ports/graphics/mesa-dri/
pkg install mesa-dri
cd /usr/ports/multimedia/libva-intel-driver/ 
pkg install libva-intel-driver
echo ""
echo ""
echo "Intel drivers installed"
echo ""

## INSTALLS THE FIRMWARE NEEDED FOR BLUETOOTH
echo "Installing UGEN IWMTFW FIRMWARE..."
echo ""
cd /usr/ports/comms/iwmbt-firmware
pkg install iwmbt-firmware
echo "Firmware installed"
echo ""

## FreeBSD SYSTEM TUNING FOR BEST DESKTOP EXPERIENCE
echo "Optimizing system parameters and firewall..."
echo ""
mv /etc/sysctl.conf /etc/sysctl.conf.bk
mv /boot/loader.conf /boot/loader.conf.bk
mv /etc/login.conf /etc/login.conf.bk
cd /etc/ && fetch https://github.com/lsime87/BSD-XFCE-INTEL-GRAPHICS/blob/main/sysctl.conf
fetch https://github.com/lsime87/BSD-XFCE-INTEL-GRAPHICS/blob/main/loader.conf
fetch https://github.com/lsime87/BSD-XFCE-INTEL-GRAPHICS/blob/main/devfs.rules
cd /boot/ && fetch https://github.com/lsime87/BSD-XFCE-INTEL-GRAPHICS/blob/main/loader.conf
sysrc devfs_system_ruleset="desktop"
cd
touch /etc/pf.conf
echo 'block in all' >> /etc/pf.conf
echo 'pass out all keep state' >> /etc/pf.conf

## CONFIGURES MORE CORE SYSTEM SERVICES
echo "Enabling additional system services..."
echo ""
sysrc pf_enable="YES"
sysrc pf_rules="/etc/pf.conf" 
sysrc pf_flags=""
sysrc pflog_enable="YES"
sysrc pflog_logfile="/var/log/pflog"
sysrc pflog_flags=""
sysrc ntpd_enable="YES"
sysrc ntpdate_enable="YES"
sysrc powerd_enable="YES"
sysrc powerd_flags="-n adaptive -a hiadaptive -m 2200 -M 4000"
sysrc performance_cx_lowest="C1"
sysrc economy_cx_lowest="Cmax"
sysrc clear_tmp_enable="YES"
sysrc syslogd_flags="-ss"
sysrc sendmail_enable="NONE"
sysrc sendmail_msp_queue_enable="NO"
sysrc sendmail_outbound_enable="NO"
sysrc sendmail_submit_enable="NO"
sysrc dumpdev="NO"
sysrc webcamd_enable="YES"

##Use your own USB port for webcam
sysrc jackd_enable="YES"
sysrc jackd_user="$user"
sysrc jackd_rtprio="YES"

## Change JACK /dev/dsp7 by your own interfaces
sysrc jackd_args="-R -doss -r48000 -p512 -n1 -w16 \
            --capture /dev/dsp7 --playback /dev/dsp7"
echo ""

## UPDATES CPU MICROCODE
echo "Updating CPU microcode..."
echo ""
pkg install -y devcpu-data
sysrc microcode_update_enable="YES"
service microcode_update start
echo ""
echo "Microcode updated"
echo ""

## CLEAN CACHES AND AUTOREMOVES UNNECESARY FILES
echo "Cleaning system..."
echo ""
pkg clean -y
pkg autoremove -y
echo ""

## DONE, PLEASE RESTART
echo "Installation done"
echo "Please, check now /boot/loader.conf and /etc/sysctl.conf if you need to make some changes"
echo "Don't forget to reboot your system after that"
echo "BSD-XFCE by Wamphyre :)"
