install
url --url=http://mirror.nextlayer.at/centos/7/os/x86_64/
lang en_US.UTF-8
keyboard us
network --device=eth0 --bootproto dhcp --onboot=yes --noipv6
rootpw --lock rootpassword
firewall --enabled --service=ssh
authconfig --enableshadow --passalgo=sha512
selinux --disabled
timezone UTC
bootloader --location=mbr
text
skipx
zerombr
clearpart --all --initlabel
part  / --size=1  --grow --fstype ext4
auth --useshadow --enablemd5
firstboot --disabled
reboot
%packages --nobase
@core
openssh-clients
openssh-server
%end
%post
/usr/bin/yum -y install sudo
sed 's/^[#[:space:]]*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
mkdir -p /root/.ssh
/bin/sh -c "echo '%SSH_KEY%' > /root/.ssh/authorized_keys"
chmod 400 /root/.ssh/authorized_keys
%end
