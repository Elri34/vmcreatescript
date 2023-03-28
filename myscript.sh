#!/bin/bash
cat <<EOF >cloud-config.yaml
#cloud-config
system_info:
  default_user:
    name: $1
    home: /home/$1
    sudo: ALL=(ALL) NOPASSWD:ALL
password: $2
chpasswd: { expire: False }
hostname: $3 
ssh_authorized_keys:
- ssh-ed25519 AAAsfdfNzasdfsdZDIgfsdgsdTE5FAKEFAKEFAKEFAKE-FAKE-FAKEWsXhHL0ah2QUUbt1f ps@controller


# if you want to allow SSH with password, set this to true
ssh_pwauth: True



# list of packages to install after the VM comes up
package_upgrade: true
packages:
- nfs-common

#run the commands after the first install, the last command is saving VM ip into /tmp/my-ip file
runcmd:
- sudo systemctl enable iscsid
- sudo systemctl start iscsid
- sudo systemctl start apache2
- ip addr show $(ip route get 1.1.1.1  |grep -oP 'dev\s+\K[^ ]+')  |grep -oP '^\s+inet\s+\K[^/]+' |tee /tmp/my-ip
- echo "KIRILL PRIVET"
EOF


if [ ! -f "debian-10-generic-amd64.qcow2" ];
then
  wget https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2
else
  echo "File debian-10-generic-amd64.qcow2 exist"
fi


qemu-img convert  -f qcow2 -O qcow2 "debian-10-generic-amd64.qcow2" "${3}-disk.qcow2";

qemu-img resize  "${3}-disk.qcow2" 20G;

cloud-localds   "${3}-CLOUD-INIT.iso"  ./cloud-config.yaml;


 virt-install   --name $3  --disk "${3}-disk.qcow2",device=disk,bus=virtio   --disk "${3}-CLOUD-INIT.iso",device=cdrom \
  --os-variant="debian10" \
  --virt-type kvm \
  --graphics vnc,listen=0.0.0.0  --noautoconsole \
  --vcpus "2" \
  --memory "2048" \
  --network network=default,model=virtio \
  --console pty,target_type=serial \
  --import ;

virsh --connect qemu:///system console $3

