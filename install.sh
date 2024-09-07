


apt-get -y update && apt-get -y upgrade

##Base dependencies
base_deps () {
  apt-get install -y libusb-1.0-0-dev libusb-1.0-0 build-essential cmake libncurses5-dev libtecla1 libtecla-dev pkg-config git wget doxygen help2man pandoc python-setuptools python-dev swig libccid pcscd pcsc-tools python-pyscard libpcsclite1 unzip firefox-esr xserver-xorg lightdm xfce4 automake matchbox-keyboard iptables-persistent
  apt install -y libbladerf-dev
}

if ! command -v <the_command> &> /dev/null
then
    echo "<the_command> could not be found"
    exit 1
fi




cp yate.service  /etc/systemd/system/yate.service
#cp config.php /usr/local/share/yate/nipc_web/config.php

## BladeRF


bladerf () {
  git clone https://github.com/Nuand/bladeRF.git
  cd bladeRF
  dpkg -s libusb-1.0-0 libusb-1.0-0-dev
  cd host/
  mkdir build
  cd build
  cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DINSTALL_UDEV_RULES=ON ../
  sudo addgroup bladerf
  sudo usermod -a -G bladerf $USER
  make && sudo make install && sudo ldconfig
}






## YatesBTS
cd ~
addgroup yate
usermod -a -G yate $USER
mkdir YateBTS
cd YateBTS
#wget https://nuand.com/downloads/yate-rc-3.tar.gz
tar xvf yate-rc-3.tar.gz
sudo mv yate /usr/src
sudo mv yatebts /usr/src
sudo mv *.rbf /usr/share/nuand/bladeRF
cd /usr/src/yate
./autogen.sh
./configure --prefix=/usr/local
make
sudo make install
sudo make install-noapi
sudo ldconfig
cd ..
cd /usr/src/yatebts
./autogen.sh
./configure --prefix=/usr/local
make
sudo make install
sudo ldconfig
cd ..
sudo mkdir -p /usr/share/nuand/bladeRF


### Configs

touch /usr/local/etc/yate/snmp_data.conf /usr/local/etc/yate/tmsidata.conf
sudo chown $USER:yate /usr/local/etc/yate/*.conf
sudo chmod g+w /usr/local/etc/yate/*.conf
bladeRF-cli -l /usr/src/Nuand/bladeRF/hostedxA9.rbf
yate -v


## NIB0x

setup_b0x () {
  sudo apt-get install -y apache2 php libusb-1.0-0 libusb-1.0-0-d* libusb-1.0-0-dev libgsm1 libgsm1-dev
  cd /var/www/html
  sudo ln -s /usr/local/share/yate/nipc_web nipc
  sudo chmod -R a+w /usr/local/share/yate
}



#wget https://raw.githubusercontent.com/Offensive-Wireless/Install-YateBTS-on-RPI4/main/yate.service



sudo systemctl daemon-reload
sudo systemctl start yate
sudo systemctl enable yate
cp config.php /usr/local/share/yate/nipc_web/config.php


## SIM Cards

sudo apt-get install libpcsclite-dev
cd ~
mkdir PySIM
cd PySIM/
git clone git://git.osmocom.org/pysim.git
sudo apt-get install python3-pyscard python3-serial python3-pip python3-yaml
pip3 install -r requirements.txt
sudo cp -R pysim/ /usr/src/
cd /usr/local/bin
sudo ln -s /usr/src/pysim/pySim-prog.py pySim-prog.py
sudo vi /usr/local/share/yate/nipc_web/config.php


sudo systemctl daemon-reload
sudo systemctl start yate
sudo systemctl enable yate




if ! command -v <the_command> &> /dev/null
then
    echo "<the_command> could not be found"
    exit 1
fi
