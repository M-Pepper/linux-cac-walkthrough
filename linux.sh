#!/bin/sh

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

apt remove cackey coolkey libckyapplet1 libckyapplet1-dev -y
apt purge -y 
apt update -y
apt upgrade -y
apt install pcsc-tools libccid libpcsc-perl libpcsclite1 pcscd opensc opensc-pkcs11 vsmartcard-vpcd libnss3-tools -y
systemctl restart pcscd.socket
systemctl restart pcscd.service
modprobe -r pn533 nfc
wget https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip
unzip unclass-certificates_pkcs7_DoD.zip
cd unclass-certificates_pkcs7_DoD
pkcs11-register
for n in *.p7b; do certutil -d sql:$HOME/.pki/nssdb -A -t TC -n $n -i $n; done
for n in *.pem; do certutil -d sql:$HOME/.pki/nssdb -A -t TC -n $n -i $n; done
wget "https://download3.vmware.com/software/CART24FQ2_LIN64_2306/VMware-Horizon-Client-2306-8.10.0-21964631.x64.bundle"
chmod +x VMware-Horizon-Client-2306-8.10.0-21964631.x64.bundle
./VMware-Horizon-Client-2209-8.7.0-20616018.x64.bundle
ln -s /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so /usr/lib/vmware/view/pkcs11/libopenscpkcs11.so
openssl pkcs7 -print_certs -in Certificates_PKCS7_v5.9_DoD.pem.p7b -out dod_bundle.pem
awk '
  split_after == 1 {n++;split_after=0}
  /-----END CERTIFICATE-----/ {split_after=1}
  {print > "cert" n ".crt"}' < dod_bundle.pem
mkdir -p /usr/local/share/ca-certificates/dod/
cp *.crt /usr/local/share/ca-certificates/dod/
update-ca-certificates
