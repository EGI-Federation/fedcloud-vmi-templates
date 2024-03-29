# Language setting
d-i debian-installer/language string en
d-i debian-installer/country string US
d-i debian-installer/locale string en_US
d-i localechooser/supported-locales en_US

# Keyboard setting
d-i console-setup/ask_detect boolean false
d-i console-setup/layoutcode string us
d-i keymap select us
d-i keyboard-configuration/xkb-keymap select us

 # Network setting
 d-i netcfg/choose_interface select auto
 d-i netcfg/get_hostname string ubuntu
#d-i netcfg/get_domain string I

# mirror
d-i mirror/country string manual
d-i mirror/http/hostname string archive.ubuntu.com
d-i mirror/http/directory string /ubuntu/
d-i mirror/http/proxy string

# Clock setting
d-i clock-setup/utc boolean true
d-i time/zone string Europe/Prague
d-i clock-setup/ntp boolean true

# Partition setting
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/device_remove_lvm boolean true

d-i partman-auto/choose_recipe select boot-root
d-i partman-auto/init_automatically_partition select biggest_free
d-i partman-auto/method string regular

d-i partman-auto/expert_recipe string                         \
      boot-root ::                                            \
              500 10000 1000000000 ext4                       \
		      method{ format } format{ }	      \
                      use_filesystem{ } filesystem{ ext4 }    \
                      mountpoint{ / }                         \
              .

d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select  finish
d-i partman/confirm_nooverwrite boolean true
d-i partman/confirm boolean true
d-i partman-basicfilesystems/no_swap boolean false
d-i partman-basicfilesystems/no_swap seen true
d-i partman/mount_style select uuid

# Account
#d-i passwd/user-fullname string temporary_user
#d-i passwd/username string temporary_user
#d-i passwd/user-password password <%= @data[:password] %>
#d-i passwd/user-password-again password <%= @data[:password] %>
#d-i user-setup/encrypt-home boolean false
#d-i user-setup/allow-password-weak boolean true
d-i passwd/make-user boolean false

# Root password
d-i passwd/root-login boolean true
d-i passwd/root-password password rootpasswd
d-i passwd/root-password-again password rootpasswd

# Base system installation
#d-i base-installer/install-recommends boolean false
d-i base-installer/kernel/image string linux-generic

# APT setting
# You can choose to install restricted and universe software, or to install
# software from the backports repository.
#d-i apt-setup/restricted boolean true
#d-i apt-setup/universe boolean true
#d-i apt-setup/backports boolean true
# Uncomment this if you don't want to use a network mirror.
#d-i apt-setup/use_mirror boolean false
# Select which update services to use; define the mirrors to be used.
# Values shown below are the normal defaults.
#d-i apt-setup/services-select multiselect security
#d-i apt-setup/security_host string security.ubuntu.com
#d-i apt-setup/security_path string /ubuntu

# package selection
tasksel tasksel/first multiselect none
d-i pkgsel/update-policy select none
d-i pkgsel/include string openssh-server
d-i pkgsel/upgrade select none

# Grub
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean false
d-i finish-install/reboot_in_progress note

# SSH hack to allow root login
d-i preseed/late_command string \
  in-target sed -i "s/PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config; \
  in-target sed -i "s/^#[\s]*PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config; \
  in-target mkdir -p /root/.ssh; \
  in-target touch /root/.ssh/authorized_keys; \
  in-target /bin/sh -c "echo '%SSH_KEY%' > /root/.ssh/authorized_keys"; \
  in-target chmod 400 /root/.ssh/authorized_keys;
