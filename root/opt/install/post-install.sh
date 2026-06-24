#!/bin/bash

btrfs subvolume create /var/lib/lxd/storage-pools/cachyos

#init
SERVICES=("syslog-ng" "lxd" "chrony" "dbus" "acpid" "chrony" "firewalld" "sshd" "turnstiled" "elogind" "lm_sensors" "dnsmasq" "fail2ban" "dhcpcd" "apparmor" "zramen")
for i in {${SERVICES[@]}}; do
dinitctl enable $i
done
# end of script
rm -rf /opt/install /etc/dinit.d/boot.d/postinstall
