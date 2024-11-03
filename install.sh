#!/bin/bash


BOX=$(pwd)


##Base dependencies
base_deps () {
  echo "Updating Repos ..."
  apt-get -y -qq update 
  echo "Upgrading System..."
  apt-get -y -qq upgrade
  echo "Installing Dependencies..."
  sudo apt-get -qq install -y libusb-1.0-0-dev libusb-1.0-0 build-essential cmake libncurses5-dev libtecla1 libtecla-dev pkg-config git wget doxygen help2man pandoc python-setuptools swig libccid pcscd pcsc-tools libpcsclite1 unzip automake matchbox-keyboard iptables-persistent
  sudo apt -qq install -y libbladerf-dev libpcsclite-dev #python-pyscard
  #box
  sudo apt-get -qq install -y apache2 php libusb-1.0-0 libusb-1.0-0-d* libusb-1.0-0-dev libgsm1 libgsm1-dev
  #SIM Cards
  sudo apt-get -qq install -y python3-pyscard python3-serial python3-pip python3-yaml
  sudo apt install -y git vim curl python-is-python3 autoconf libtool libosmocore  
  sudo apt-get install -y libusb-1.0-0-dev libboost-dev g++ cmake libsqlite3-dev
  sudo apt-get install -y libuhd-dev uhd-host liburing* libpcsclite* gnutls* libortp-dev libosmo-sccp*  libdbi* htop libedit* libxml2-dev asterisk
  sudo apt-get install -y libsoapysdr-dev libi2c-dev libusb-1.0-0-dev ibwxgtk* freeglut3-dev gnuplot libghc-tls* libmnl-dev libsctp-dev
  sudo apt install -y libpcsclite-dev libtalloc-dev libortp-dev libsctp-dev libmnl-dev libdbi-dev libdbd-sqlite3 libsqlite3-dev sqlite3 libc-ares-dev libxml2-dev libssl-dev
  sudo apt install libdbi-dev libdbd-sqlite3 libortp-dev build-essential libtool autoconf autoconf-archive automake git-core pkg-config libtalloc-dev libpcsclite-dev libpcap-dev
  sudo apt-get install raspi-config
}

## LimeSDR

limesdr()
{
  ## LimeSuite
git clone https://github.com/myriadrf/LimeSuite.git
cd LimeSuite
mkdir buildir && cd buildir
cmake ../
make -j4
sudo make install
sudo ldconfig
cd ..
cd  udev-rules
sudo sh ./install.sh
cd ../..
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
  if [ $(getent group bladerf) ]; then
  echo "BladeRF group exists."
  else
    echo "Group BladeRF does not exist."
    sudo addgroup bladerf
  fi
  bladeRF-cli -l /usr/src/Nuand/bladeRF/hostedxA9.rbf
  make && sudo make install && sudo ldconfig
  cd $BOX
}


# YatesBTS Install
YatesBTS_install () {
  echo "Installing YateBTS..."
  if [ $(getent group yate) ]; then
  echo "Yate group exists."
  else
    echo "Group Yate does not exist."
    sudo addgroup yate
    sudo usermod -a -G yate $USER
  fi
  #wget https://nuand.com/downloads/yate-rc-3.tar.gz
  cd $BOX
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
  cd $BOX
}

### Configs
YatesBTS_config () {
  echo "Configuring ... \n"
  cd $BOX




  if [ -x /etc/systemd/system/yate.service ]; then
      echo "Yate Service Already Exists..."
  else
      echo "Copying Yate Services data... \n"
      sudo cp yate.service  /etc/systemd/system/
      sudo chown $USER:yate /usr/local/etc/yate/*.conf
      sudo chmod g+w /usr/local/etc/yate/*.conf
  fi

  if [ -x /usr/local/etc/yate/snmp_data.conf ]; then
      echo "snmp_data Already Exists..."
  else
      echo "Copying Yate Service to SystemD... \n"
      sudo touch /usr/local/etc/yate/snmp_data.conf
  fi

  if [ -x /usr/local/etc/yate/tmsidata.conf ]; then
      echo "tmsidata Already Exists..."
  else
      echo "Copying Yate Service to SystemD... \n"
      sudo touch /usr/local/etc/yate/tmsidata.conf
  fi


  

  echo "Restarting YateBTS... \n"
  sudo systemctl daemon-reload
  sudo systemctl start yate
  sudo systemctl enable yate
  cd $HOME
}

## NIB0x
setup_b0x () {
  echo "Setup B0x \n"
  cd /var/www/html
    if [ -x /usr/local/share/yate/nipc_web ]; then
      echo "YateBTS GUI Already Installed..."
  else
      echo "Installing YateBTS GUI \n"
      sudo ln -s /usr/local/share/yate/nipc_web nipc
      sudo chmod -R a+w /usr/local/share/yate
      echo -e "Restarting Apache... \n"
      sudo systemctl daemon-reload
      sudo systemctl restart apache2
      sudo systemctl enable apache2
      cd $BOX
  fi
 if [ -x /usr/local/share/yate/nipc_web/config.php ]; then
      echo "config Already Exists..."
  else
      echo "Copying Yate Service to SystemD... \n"
      cd $BOX
      cp config.php /usr/local/share/yate/nipc_web/
  fi

}



## SIM Cards
sim_cards () {
  if [ -x /usr/src/pysim/pySim-prog.py ]; then
      echo "PySIM Already Installed..."
  else
      echo "Installing PySIM \n"
      git clone git://git.osmocom.org/pysim.git
      pip3 install -r requirements.txt
      sudo cp -R pysim/ /usr/src/
      cd /usr/local/bin
      sudo ln -s /usr/src/pysim/pySim-prog.py pySim-prog.py
  fi

}


banner () {
  echo -e " Install Rogue BTS on RPI4 Ubuntu 22.04 "
  echo -e "
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  | OS: $(uname)                                   |
  | Kernel: $(uname -n)                            |
  | User: $USER                                    |     
  | Project Folder: $BOX                           |
  | Author: RFS                                    |
  | Status: In Dev - DO NOT USE                    |
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#\n"
}



function OPTIONS() {    
banner
echo -e "
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
| 0.) System preparation                         |
| 1.) Install YateBTS (2G)                       |
| 2.) Install srsLTE eNB (4G)                    |
| 3.) Install BladeRF - Radio                    | 
| 4.) Install LimeSDR - Radio                    |     
| 5.) Install PySIM - SIM Cards                  |
| 6.) Quit                                       |
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#\n"

read -e -p "Select the Choice: " choice

if [ "$choice" == "0" ]; then
    echo -e "System preparation...\n"
    base_deps
 
elif [ "$choice" == "1" ]; then

    echo -e "Installing YateBTS...\n"
    YatesBTS_install
    echo -e "Configuring YateBTS...\n"
    YatesBTS_config

        
elif [ "$choice" == "2" ]; then

    echo -e "Installing srsLTE eNB...\n"

elif [ "$choice" == "3" ]; then

    echo -e "Installing BladeRF ...\n"
    bladerf

elif [ "$choice" == "4" ]; then

    echo -e "Installing LimeSDR ...\n"
    limesdr

elif [ "$choice" == "5" ]; then

        echo "Installing PySIM..."
        sim_cards
        
elif [ "$choice" == "6" ]; then

    clear && exit 0

else

    echo "Please select 1, 2, 3,4 ,5 or 6." && sleep 3
    clear && OPTIONS

fi
}

OPTIONS
