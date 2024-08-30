

lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts='us'
network  --bootproto=dhcp --device=link --activate
# network installation
url --url https://repo.almalinux.org/almalinux/9/BaseOS/x86_64/kickstart/
repo --name=BaseOS --baseurl=https://repo.almalinux.org/almalinux/9/BaseOS/x86_64/os/
repo --name=AppStream --baseurl=https://repo.almalinux.org/almalinux/9/AppStream/x86_64/os/
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

%post --erroronfail
for x in $(cat /proc/cmdline)
do
  case $x in
    PACKER_AUTHORIZED_KEY=*)
      # URL decode $encoded into $PACKER_AUTHORIZED_KEY
      encoded=$(echo "${x#*=}" | tr '+' ' ')
      printf -v PACKER_AUTHORIZED_KEY '%b' "${encoded//%/\\x}"
      ;;
  esac
done

echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/01-permitrootlogin.conf
mkdir -p /root/.ssh
echo $PACKER_AUTHORIZED_KEY >> /root/.ssh/authorized_keys
chmod 400 /root/.ssh/authorized_keys
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end
