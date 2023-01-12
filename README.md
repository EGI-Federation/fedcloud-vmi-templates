# FedCloud VM Image templates

This repository contains the packer templates used for creating the EGI
Virtual Machine Images that are available at [AppDB](https://appdb.egi.eu/browse/cloud)

Initial work taken from [comfy](https://github.com/Misenko/comfy)

## Building the images

There is a `tools/build.sh` script that can be used to build image and convert
to OVA in one go. The script will create a temporary ssh key that's used to
by packer to connect to the VM as root (or privileged user).

The script takes as parameter the `.json` that describe the build for packer.
See sample build output:

```shell
ubuntu@builder:~/fedcloud-vmi-templates/centos$ sudo ../tools/build.sh centos-7.json
Generating public/private ed25519 key pair.
Your identification has been saved in /tmp/tmp.isFiNAk2AM/key
Your public key has been saved in /tmp/tmp.isFiNAk2AM/key.pub
The key fingerprint is:
SHA256:zu1CahLOPhThaxpWF+VhroQAZWZr/KWuT6tKO5QpMpc root@builder
The key's randomart image is:
+--[ED25519 256]--+
|.o*    .+        |
| = o...+ .       |
|  +...o.o        |
| . .++..         |
|  ooo+. S        |
|++E.=  o..       |
|+= Bo. oo .      |
|..oo=.o ..       |
|.o++++   ..      |
+----[SHA256]-----+
qemu: output will be in this color.

==> qemu: Retrieving ISO
==> qemu: Trying https://mirror.netcologne.de/centos/7/isos/x86_64/CentOS-7-x86_64-NetInstall-2009.iso
==> qemu: Trying https://mirror.netcologne.de/centos/7/isos/x86_64/CentOS-7-x86_64-NetInstall-2009.iso?checksum=sha256%3Ab79079ad71cc3c5ceb3561fff348a1b67ee37f71f4cddfec09480d4589c191d6
==> qemu: https://mirror.netcologne.de/centos/7/isos/x86_64/CentOS-7-x86_64-NetInstall-2009.iso?checksum=sha256%3Ab79079ad71cc3c5ceb3561fff348a1b67ee37f71f4cddfec09480d4589c191d6 => /root/.cache/packer/fa66676a0cae1de79d03c97423c2624780bea13a.iso
==> qemu: Starting HTTP server on port 8533
==> qemu: Found port for communicator (SSH, WinRM, etc): 2446.
==> qemu: Looking for available port between 5928 and 5928 on 127.0.0.1
==> qemu: Starting VM, booting from CD-ROM
    qemu: The VM will be run headless, without a GUI. If you want to
    qemu: view the screen of the VM, connect via VNC without a password to
    qemu: vnc://127.0.0.1:5928
==> qemu: Overriding default Qemu arguments with qemuargs template option...
==> qemu: Waiting 10s for boot...
==> qemu: Connecting to VM via VNC (127.0.0.1:5928)
==> qemu: Typing the boot command over VNC...
    qemu: Not using a NetBridge -- skipping StepWaitGuestAddress
==> qemu: Using SSH communicator to connect: 127.0.0.1
==> qemu: Waiting for SSH to become available...
==> qemu: Connected to SSH!
==> qemu: Provisioning with Ansible...
    qemu: Not using Proxy adapter for Ansible run:
    qemu:       Using ssh keys from Packer communicator...
==> qemu: Executing Ansible: ansible-playbook -e packer_build_name="qemu" -e packer_builder_type=qemu -e packer_http_addr=10.0.2.2:8533 --ssh-extra-args '-o IdentitiesOnly=yes' -e ansible_ssh_private_key_file=/tmp/tmp.isFiNAk2AM/key -i /tmp/packer-provisioner-ansible3719429610 /home/ubuntu/fedcloud-vmi-templates/centos/provisioners/init.yaml
    qemu:
    qemu: PLAY [all] *********************************************************************
    qemu:
    qemu: TASK [install python] **********************************************************
    qemu: changed: [default]
    qemu:
    qemu: PLAY [all] *********************************************************************
    qemu:
    qemu: TASK [Gathering Facts] *********************************************************
    qemu: ok: [default]
    qemu:
    qemu: TASK [update packages] *********************************************************
    qemu: changed: [default]
    qemu:
    qemu: TASK [get the rpm package facts] ***********************************************
    qemu: ok: [default]
    qemu:
    qemu: TASK [Rebuilding initramfs for kernel] *****************************************
    qemu: changed: [default] => (item={'name': 'kernel', 'source': 'rpm', 'epoch': None, 'version': '3.10.0', 'release': '1160.81.1.el7', 'arch': 'x86_64'})
    qemu: changed: [default] => (item={'name': 'kernel', 'source': 'rpm', 'epoch': None, 'version': '3.10.0', 'release': '1160.el7', 'arch': 'x86_64'})
    qemu:
    qemu: PLAY RECAP *********************************************************************
    qemu: default                    : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    qemu:
==> qemu: Provisioning with shell script: /tmp/packer-shell2858417963
==> qemu: Pausing 30s before the next provisioner...
==> qemu: Provisioning with Ansible...
    qemu: Not using Proxy adapter for Ansible run:
    qemu:       Using ssh keys from Packer communicator...
==> qemu: Executing Ansible: ansible-playbook -e packer_build_name="qemu" -e packer_builder_type=qemu -e packer_http_addr=10.0.2.2:8533 --ssh-extra-args '-o IdentitiesOnly=yes' -e ansible_ssh_private_key_file=/tmp/tmp.isFiNAk2AM/key -i /tmp/packer-provisioner-ansible2057822301 /home/ubuntu/fedcloud-vmi-templates/centos/provisioners/config.yaml
    qemu:
    qemu: PLAY [all] *********************************************************************
    qemu:
    qemu: TASK [Gathering Facts] *********************************************************
    qemu: ok: [default]
    qemu:
    qemu: TASK [Include cloud-init recipe] ***********************************************
    qemu: included: /home/ubuntu/fedcloud-vmi-templates/centos/provisioners/cloud-init.yaml for default
    qemu:
    qemu: TASK [install epel] ************************************************************
    qemu: changed: [default]
    qemu:
    qemu: TASK [install cloud-init and extra packages] ***********************************
    qemu: changed: [default]
    qemu:
    qemu: TASK [extra packages for centos 6] *********************************************
    qemu: skipping: [default]
    qemu:
    qemu: TASK [copy cloud-init patch] ***************************************************
    qemu: changed: [default]
    qemu:
    qemu: TASK [patch cloud-init] ********************************************************
    qemu: skipping: [default]
    qemu:
    qemu: TASK [Create fedcloud config] **************************************************
    qemu: changed: [default]
    qemu:
    qemu: TASK [enable service] **********************************************************
    qemu: ok: [default] => (item=cloud-init-local)
    qemu: ok: [default] => (item=cloud-init)
    qemu: ok: [default] => (item=cloud-config)
    qemu: ok: [default] => (item=cloud-final)
    qemu:
    qemu: TASK [Include "7" network recipe] **********************************************
    qemu: included: /home/ubuntu/fedcloud-vmi-templates/centos/provisioners/network-centos7.yaml for default
    qemu:
    qemu: TASK [Create /etc/sysconfig/network] *******************************************
    qemu: changed: [default]
    qemu:
    qemu: TASK [Create /etc/sysconfig/network-scripts/ifcfg-eth0] ************************
    qemu: changed: [default]
    qemu:
    qemu: TASK [enable network service] **************************************************
    qemu: ok: [default]
    qemu:
    qemu: TASK [disable network manager] *************************************************
    qemu: changed: [default]
    qemu:
    qemu: TASK [Include clean-up recipe] *************************************************
    qemu: included: /home/ubuntu/fedcloud-vmi-templates/centos/provisioners/clean.yaml for default
    qemu:
    qemu: TASK [remote ssh keys] *********************************************************
    qemu: ok: [default] => (item=/etc/ssh/ssh_host_dsa_key.pub)
    qemu: changed: [default] => (item=/etc/ssh/ssh_host_ecdsa_key)
    qemu: changed: [default] => (item=/etc/ssh/ssh_host_rsa_key.pub)
    qemu: changed: [default] => (item=/etc/ssh/ssh_host_rsa_key)
    qemu: changed: [default] => (item=/etc/ssh/ssh_host_ecdsa_key.pub)
    qemu: changed: [default] => (item=/etc/ssh/ssh_host_ed25519_key)
    qemu: ok: [default] => (item=/etc/ssh/ssh_host_dsa_key)
    qemu: changed: [default] => (item=/etc/ssh/ssh_host_ed25519_key.pub)
    qemu:
    qemu: TASK [disable root login] ******************************************************
    qemu: changed: [default]
    qemu:
    qemu: TASK [disable pasword authentication] ******************************************
    qemu: changed: [default]
    qemu:
    qemu: TASK [lock root password] ******************************************************
    qemu: changed: [default]
    qemu:
    qemu: TASK [remove unneeded files] ***************************************************
    qemu: ok: [default] => (item=/root/.bash_history)
    qemu: ok: [default] => (item=/root/VBoxGuestAdditions.iso)
    qemu:
    qemu: TASK [fill disk with zeros] ****************************************************
    qemu: changed: [default]
    qemu:
    qemu: PLAY RECAP *********************************************************************
    qemu: default                    : ok=19   changed=12   unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
    qemu:
==> qemu: Provisioning with shell script: provisioners/cleanup.sh
==> qemu: + sudo rm -fr '/home/*/.ssh' '/home/*/.ansible' '/home/*/.cache'
==> qemu: + sudo rm -fr /root/.ssh /root/.ansible /root/.cache
==> qemu: + sudo rm -fr '/root/~*'
==> qemu: Gracefully halting virtual machine...
==> qemu: Converting hard drive...
Build 'qemu' finished after 13 minutes 10 seconds.

==> Wait completed after 13 minutes 10 seconds

==> Builds finished. The artifacts of successful builds are:
--> qemu: VM files in directory: output-qemu
Virtual machine 'centos.7-2023.01.12' is created and registered.
UUID: 3b3258fc-14c4-4c35-a458-26b6cedc22f6
Settings file: '/root/VirtualBox VMs/centos.7-2023.01.12/centos.7-2023.01.12.vbox'
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Successfully exported 1 machine(s).
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Converted image available at centos.7-2023.01.12.ova
```

## Acknowledgement

This work is co-funded by the [EOSC-hub project](http://eosc-hub.eu/) (Horizon 2020) under Grant number 777536.
<img src="https://wiki.eosc-hub.eu/download/attachments/1867786/eu%20logo.jpeg?version=1&modificationDate=1459256840098&api=v2" height="24">
<img src="https://wiki.eosc-hub.eu/download/attachments/18973612/eosc-hub-web.png?version=1&modificationDate=1516099993132&api=v2" height="24">
