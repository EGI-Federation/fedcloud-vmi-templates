

lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts='us'
network  --bootproto=dhcp --device=link --activate
# network installation
url --mirrorlist="http://mirrorlist.centos.org/?release=8-stream&arch=x86_64&repo=BaseOS&infra=$infra"
rootpw --plaintext rootpassword

firewall --enabled --service=ssh
selinux --disabled
timezone UTC
bootloader --location=mbr
text
skipx

zerombr
clearpart --all --initlabel
part  / --size=1  --grow --fstype ext4
firstboot --disabled
reboot

%packages
@^minimal-environment
openssh-clients
openssh-server
sudo
kexec-tools
%end

%post
/usr/bin/yum -y install sudo
sed 's/^[#[:space:]]*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
mkdir -p /root/.ssh
/bin/sh -c "echo '%SSH_KEY%' > /root/.ssh/authorized_keys"
chmod 400 /root/.ssh/authorized_keys
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end
