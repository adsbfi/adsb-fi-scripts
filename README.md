# ADS-B Exchange Setup Scripts :airplane:

These scripts aid in setting up your current ADS-B receiver to feed ADS-B Exchange.

### Obtaining And Using The Scripts

Running the following commands will download the contents of this repository and begin setup.

    sudo apt-get install git
    git clone https://github.com/adsbxchange/adsb-exchange.git
    cd adsb-exchange
    chmod +x setup.sh
    sudo ./setup.sh
    
**After completing the setup do not delete this repository.**

The script creates two files, one named adsbexchange-mlat_maint.sh and another named adsbexchange-netcat_maint.sh which will reside in this folder containing a clone of this repository. The path to execute these scripts after each reboot has been set to this location. Deleting this folder will result in both the adsbexchange-mlat_maint.sh and adsbexchange-netcat_maint.sh scripts to not be executed thus not enabling your receiver to feed ADS-B Exchange after your device has been rebooted.

### Reporting Issues

Feel free to report any issues you encounter to one of the following locations:

http://adsbreceiver.net/forum/cat/ads-b-exchange-setup-script/ 
https://github.com/jprochazka/adsb-exchange_setup/issues  
