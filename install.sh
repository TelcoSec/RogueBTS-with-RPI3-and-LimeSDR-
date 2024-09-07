#!/bin/bash



echo "Updating Repos ...\n"
apt-get -y -qq update 
echo "Upgrading System...\n"
apt-get -y -qq upgrade

##Base dependencies
base_deps () {
  echo "Installing Dependencies..."
  sudo apt-get -qq install -y libusb-1.0-0-dev libusb-1.0-0 build-essential cmake libncurses5-dev libtecla1 libtecla-dev pkg-config git wget doxygen help2man pandoc python-setuptools swig libccid pcscd pcsc-tools libpcsclite1 unzip automake matchbox-keyboard iptables-persistent
  sudo apt -qq install -y libbladerf-dev libpcsclite-dev #python-pyscard
  #box
  sudo apt-get -qq install -y apache2 php libusb-1.0-0 libusb-1.0-0-d* libusb-1.0-0-dev libgsm1 libgsm1-dev
  #SIM Cards
  sudo apt-get -qq install -y python3-pyscard python3-serial python3-pip python3-yaml
}


## BladeRF
bladerf () {
  echo "Configuring BladeRF \n"
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
  cd $HOME
}


# YatesBTS Install
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
  cd $HOME
}

### Configs
YatesBTS_config () {
  echo "Configuring ... \n"
  touch /usr/local/etc/yate/snmp_data.conf /usr/local/etc/yate/tmsidata.conf
  sudo chown $USER:yate /usr/local/etc/yate/*.conf
  sudo chmod g+w /usr/local/etc/yate/*.conf
  bladeRF-cli -l /usr/src/Nuand/bladeRF/hostedxA9.rbf
  cp yate.service  /etc/systemd/system/yate.service
  cp config.php /usr/local/share/yate/nipc_web/config.php
  cd $HOME
}

## NIB0x
setup_b0x () {
  echo "Setup B0x \n"
  cd /var/www/html
  sudo ln -s /usr/local/share/yate/nipc_web nipc
  sudo chmod -R a+w /usr/local/share/yate
  cd $HOME
}



#wget https://raw.githubusercontent.com/Offensive-Wireless/Install-YateBTS-on-RPI4/main/yate.service

restart_services () {
  echo "Reload Services... \n"
  sudo systemctl daemon-reload
  echo "Restarting YateBTS... \n"
  sudo systemctl start yate
  sudo systemctl enable yate
  echo "Restarting Apache... \n"
  sudo systemctl start apache2
  sudo systemctl enable apache2
}


cp config.php /usr/local/share/yate/nipc_web/config.php


## SIM Cards
sim_cards () {
  echo "Installing PySIM \n"
  git clone git://git.osmocom.org/pysim.git
  pip3 install -r requirements.txt
  sudo cp -R pysim/ /usr/src/
  cd /usr/local/bin
  sudo ln -s /usr/src/pysim/pySim-prog.py pySim-prog.py
  sudo vi /usr/local/share/yate/nipc_web/config.php
  cd $HOME
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
YatesBTS_config
#6
setup_b0x
#7
sim_cards
#8 last
restart_services



function OPTIONS() {    
banner
echo -e "
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
| 0.) Install Dependencies                                |
| 1.) Install YateBTS                                |
| 2.) Install BladeRF               |     
| 3.) Install PySIM                   |
| 4.) Quit                                       |
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#\n"

read -e -p "Select the Choice: " choice

if [ "$choice" == "0" ]; then
    echo "logging in to the Azure..."
    base_deps
 
elif [ "$choice" == "1" ]; then

    echo "logging in to non-prod2 evn..."
    YatesBTS_install
    echo "logging in to non-prod2 evn..."
    YatesBTS_config

        
elif [ "$choice" == "2" ]; then

    echo "Configure YateBTS GUI...\n"
    setup_b0x

elif [ "$choice" == "3" ]; then

        echo "logging in to prod3 evn..."
        sim_cards
        
elif [ "$choice" == "4" ]; then

    clear && exit 0

else

    echo "Please select 1, 2, 3, or 4." && sleep 3
    clear && OPTIONS

fi
}

OPTIONS
