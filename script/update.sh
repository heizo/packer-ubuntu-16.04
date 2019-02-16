#!/bin/bash -eu

# Disable automatic updates
echo "==> Disabling apt.daily.service & apt-daily-upgrade.service"
systemctl stop apt-daily.timer apt-daily-upgrade.timer
systemctl mask apt-daily.timer apt-daily-upgrade.timer
systemctl stop apt-daily.service apt-daily-upgrade.service
systemctl mask apt-daily.service apt-daily-upgrade.service
systemctl daemon-reload

# install packages and upgrade
echo "==> Updating list of repositories"
apt-get -y update
if [[ $UPDATE =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    apt-get -y dist-upgrade
fi
apt-get -y install --no-install-recommends build-essential linux-headers-generic
apt-get -y install --no-install-recommends ssh nfs-common curl git vim

# Disable release upgrader
#echo "==> Disabling the release upgrader"
#sed -i 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades
echo "==> Removing the release upgrader"
apt-get -y purge ubuntu-release-upgrader-core
rm -rf /var/lib/ubuntu-release-upgrader
rm -rf /var/lib/update-manager

# Clean up the apt cache
apt-get -y autoremove --purge
apt-get -y clean

# Disable IPv6
if [[ $DISABLE_IPV6 =~ true || $DISABLE_IPV6 =~ 1 || $DISABLE_IPV6 =~ yes ]]; then
    echo "==> Disabling IPv6"
    sed -i -e 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' \
        /etc/default/grub
    #update-grub
fi

# Remove 5s grub timeout to speed up booting
sed -i -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' \
    -e '/^GRUB_TIMEOUT=/iGRUB_TIMEOUT_STYLE=hidden' \
    -e 's/^GRUB_HIDDEN_/#GRUB_HIDDEN_/' \
    -e 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet nosplash"/' \
    /etc/default/grub
update-grub

# SSH tweaks
echo "UseDNS no" >> /etc/ssh/sshd_config

# Add delay to prevent "vagrant reload" from failing
echo "pre-up sleep 2" >> /etc/network/interfaces

# Reboot
echo "====> Shutting down the SSHD service and rebooting..."
systemctl stop sshd.service
nohup shutdown -r now < /dev/null > /dev/null 2>&1 &
sleep 120
exit 0
