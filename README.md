# ADS-B Exchange Setup Script :airplane:

Feeding ADSBexchange.com is quick and easy. There are various options depending on what kind of feeder/receiver you use,
and your desired level of customization. This script aids in setting up your current PiAware or Dump1090 based feeder to
feed ADS-B Exchange. Although not required it is recommended that FlightAware’s PiAware be used to feed data to
ADSB-Exchange in order to send the most accurate MLAT results to the co-op.

#### Obtaining And Using This Script

Running the following commands will download the contents of this repository.

    sudo apt-get install git
    git clone https://github.com/jprochazka/adsb-exchange.git
    cd adsb-exchange
    
Depending on if you have PiAware setup or are running Dump1090...

**PiAware**

    chmod 755 piaware_setup.sh
    ./piaware_setup.sh
    
**Dump1090**

    chmod 755 dump1090_setup.sh
    ./dump1090_setup.sh

#### Reporting Issues

Feel free to report any issues you encounter either in this repositories issue tracker or the ADS-B Exchange Setup Script
topic located in the ADS-B Exchange forums.

https://github.com/jprochazka/adsb-exchange_setup/issues  
http://www.adsbexchange.com/forums/topic/ads-b-exchange-setup-script/

