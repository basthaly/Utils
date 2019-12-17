#!/bin/bash

case $# in

0)
    echo -e "Rentrer l'adresse à donner au Raspberry : "
    read address
    echo -e "Rentrer le masque à donner au Raspberry : "
    read masque
    echo -e "Rentrer la gateway à donner au Raspberry : "
    read gateway
;;

1)  
    address=$1
    echo -e "Rentrer le masque à donner au Raspberry : "
    read masque
    echo -e "Rentrer la gateway à donner au Raspberry : "
    read gateway
;;

2)  
    address=$1
    masque=$2
    echo -e "Rentrer la gateway à donner au Raspberry : "
    read gateway
;;

3)  
    address=$1
    masque=$2
    gateway=$3
;;

esac

sudo ip a f dev eth0

sudo -s <<eof
echo "
auto eth0
iface eth0 inet static
        address $address
        netmask $masque
        gateway $gateway
" > /etc/network/interfaces.d/eth0
eof

sudo service networking restart

fichier="/etc/sysctl.conf"
oldIFS=$IFS     # sauvegarde du séparateur de champ
IFS=$'\n'       # nouveau séparateur de champ, le caractère fin de ligne
a=0

>~/fichier
for ligne in $(<$fichier)
do
   var=$(echo $ligne | cut -d" " -f1)
   if [ "$var" == "net.ipv6.conf.all.disable_ipv6" -o "$var" == "net.ipv6.conf.all.autoconf" -o "$var" == "net.ipv6.conf.default.disable_ipv6" -o "$var" == "net.ipv6.conf.default.autoconf" ]; then
        :
   else
        echo "$ligne" >> ~/fichier
   fi
   a=`expr $a + 1`
done

sudo mv ~/fichier $fichier

IFS=$oldIFS

sudo -s <<eof
echo "
net.ipv6.conf.all.disable_ipv6 = 1

net.ipv6.conf.all.autoconf = 0

net.ipv6.conf.default.disable_ipv6 = 1

net.ipv6.conf.default.autoconf = 0
" >> $fichier
eof

sudo sysctl -p

if [ -z "$(ip a | grep secondary)" ]; then
    :
else
    sudo update-rc.d dhcpcd disable
    sudo service dhcpcd stop
    sudo ip addr del $(ip a | grep secondary | awk '{print $2}') dev eth0
fi