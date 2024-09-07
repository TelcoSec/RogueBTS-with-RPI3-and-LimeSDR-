


$BASE=$PWD

apt-get -y -qq update && apt-get -y upgrade

##Base dependencies
base_deps () {
  echo "Installing Dependencies..."
  sudo apt-get -qq install -y libusb-1.0-0-dev libusb-1.0-0 build-essential cmake libncurses5-dev libtecla1 libtecla-dev pkg-config git wget doxygen help2man pandoc python-setuptools swig libccid pcscd pcsc-tools libpcsclite1 unzip automake matchbox-keyboard iptables-persistent
  sudo apt -qq install -y libbladerf-dev libpcsclite-dev #python-pyscard
}

if ! command -v <the_command> &> /dev/null
then
    echo "<the_command> could not be found"
    exit 1
fi






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
  cd $BASE
}



YatesBTS_install () {
  echo "Installing YateBTS..."
  sudo addgroup yate
  sudo usermod -a -G yate $USER
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
  cd /usr/src/yatebts
  ./autogen.sh
  ./configure --prefix=/usr/local
  make
  sudo make install
  sudo ldconfig
  cd ..
  sudo mkdir -p /usr/share/nuand/bladeRF
  cd $BASE
}


YatesBTS_config () {
  commands
}

### Configs
configs () {
  touch /usr/local/etc/yate/snmp_data.conf /usr/local/etc/yate/tmsidata.conf
  sudo chown $USER:yate /usr/local/etc/yate/*.conf
  sudo chmod g+w /usr/local/etc/yate/*.conf
  bladeRF-cli -l /usr/src/Nuand/bladeRF/hostedxA9.rbf
  cp yate.service  /etc/systemd/system/yate.service
  cp config.php /usr/local/share/yate/nipc_web/config.php
  cd $BASE
}

## NIB0x
setup_b0x () {
  sudo apt-get -qq install -y apache2 php libusb-1.0-0 libusb-1.0-0-d* libusb-1.0-0-dev libgsm1 libgsm1-dev
  cd /var/www/html
  sudo ln -s /usr/local/share/yate/nipc_web nipc
  sudo chmod -R a+w /usr/local/share/yate
  cd $BASE
}



#wget https://raw.githubusercontent.com/Offensive-Wireless/Install-YateBTS-on-RPI4/main/yate.service

restart_services () {
  sudo systemctl daemon-reload
  sudo systemctl start yate
  sudo systemctl enable yate
  sudo systemctl start apache2
  sudo systemctl enable apache2
}


cp config.php /usr/local/share/yate/nipc_web/config.php


## SIM Cards
sim_cards () {
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
  cd $BASE
}


banner () {
  echo """ Install Rogue BTS on RPI4 Ubuntu 22.04 \n"""
}



#1
banner
#2
base_deps
#3
bladerf
#4
YatesBTS_install
#5
configs
#6
setup_b0x
#7
sim_cards
#8 last
restart_services
