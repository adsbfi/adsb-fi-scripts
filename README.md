# ADS-B Exchange Setup Script :airplane:

Feeding ADSBexchange.com is quick and easy. There are various options depending on what kind of feeder/receiver you use,
and your desired level of customization. it is recommended that FlightAware’s Raspberry Pi based “PiAware” be used to feed
data to ADSB-Exchange in order to send accurate MLAT results to the co-op.

This setup script aids in setting up your current PiAware based feeder to feed ADS-B Exchange as well.

#### Obtaining And Using This Script

Running the following commands will download and execute the script.

    sudo apt-get install git wget
    git clone https://github.com/jprochazka/adsb-exchange_setup.git
    cd adsb-exchange_setup
    chmod 755 adsb-exchange_setup.sh 
    ./adsb-exchange_setup.sh
    
#### Reporting Issues

Feel free to report any issues you encounter either in this repositories issue tracker or the ADS-B Exchange Setup Script
topic located in the ADS-B Exchange forums.

https://github.com/jprochazka/adsb-exchange_setup/issues  
http://www.adsbexchange.com/forums/topic/ads-b-exchange-setup-script/
