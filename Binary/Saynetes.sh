# removing module from kernel
sioIsPresent=lsmod | grep ftdi_sio | wc -l
echo $sioIsPresent
if [ $sioIsPresent -eq 1 ]
then
  sudo rmmod ftdio_sio
fi

usbserialIsPresent=lsmod | grep usbserial | wc -l
echo $usbserialIsPresent
if [ $usbserialPresent -eq 1 ]; then sudo rmmod usbserial; fi

libahciIsPresent=lsmod | grep libahci | wc -l
if [ libahciIsPresent -eq 1]; then echo "libahci est present"; fi

# Launch the program
sudo ./Saynetes
