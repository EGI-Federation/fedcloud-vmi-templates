# FedCloud VM Image templates

This repository contains the packer templates used for creating the EGI Virtual
Machine Images that are available at the [EGI Artefact Registry](https://registry.egi.eu)

Initial work taken from [comfy](https://github.com/Misenko/comfy)

## Building the images

The repository has a GitHub action workflow that will build images from
changes detected in the `*.hcl` files. This starts a VM at an EGI site (SCAI)
that will:

1. get the repository files at the current commit
1. install packer
1. build the image described in the hcl templates
1. upload the image to the local OpenStack glance and test it with IM
1. clean up the image at glance

when a PR is merged it will also:
1. upload the resulting image to the [EGI Artefact Registry](https://registry.egi.eu)

### Building manually

#### Requirements

From a base Ubuntu 24.04, you can get a working building environment by
installing `packer`, `ansible`, `qemu`, and `jq`, e.g.:

```shell
# get up to date system
$ sudo apt-get update && sudo apt-get upgrade -y
# Install packer
$ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo tee /etc/apt/trusted.gpg.d/hashicorp.asc
$ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
$ sudo apt-get update && sudo apt-get install -y packer
# Install other tools
$ sudo apt-get install -y ansible qemu-system-x86 qemu-utils jq
# Install packer plugins
$ packer plugins install github.com/hashicorp/qemu
$ packer plugins install github.com/hashicorp/ansible
```

#### Building

There is a `tools/build.sh` script that can be used to build image and convert
to OVA in one go. The script will create a temporary ssh key that's used by
packer to connect to the VM as root (or privileged user).

The script takes as parameter the `.hcl` that describe the build for packer.
See sample build output:

```shell
$ cd fedcloud-vmi-templates/ubuntu
$ export PACKER_LOG=1
$ export PACKER_LOG_PATH=packer.log
$ sudo --preserve-env ../tools/build.sh ubuntu-20.04.pkr.hcl
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
```

## Acknowledgements

The work was supported by [EGI-ACE](https://www.egi.eu/project/egi-ace/) project
with funding from the European Union’s Horizon 2020 research and innovation
programme under grant agreement No. 101017567.

This work was co-funded by the [EOSC-hub project](http://eosc-hub.eu/)
(Horizon 2020) under Grant number 777536.
