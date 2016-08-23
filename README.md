# ADS-B Exchange Setup Scripts :airplane:

These scripts aids in setting up your current ADS-B receiver to feed ADS-B Exchange. 

### Obtaining And Using The Scripts

Running the following commands will download the contents of this repository and begin setup.

    sudo apt-get install git
    git clone https://github.com/jprochazka/adsb-exchange.git
    cd adsb-exchange
    chmod +x setup.sh
    sudo ./setup.sh
    
**After completing the setup do not delete this repository.**

The script(s) create two files, one named adsbexchange-mlat_maint.sh and another named adsbexchange-netcat_maint.sh which will reside in this folder containing a clone of this repository. The path to execute these scripts after a reboot has been set to this location. Deleting this folder will result in both the adsbexchange-mlat_maint.sh and adsbexchange-netcat_maint.sh script not being executed thus not enabling your receiver to feed ADS-B Exchange after your device has been rebooted.

**no_dialogs.sh**

The file "no_dialogs.sh" can used in place of "setup.sh" to set up your receiver.  
The only difference between the two files is "no_dialogs.sh" does not use Whiptail dialogs.

### Reporting Issues

Feel free to report any issues you encounter to one of the following locations:

https://www.adsbreceiver.net/forums/forum/ads-b-exchange-setup-scripts/
https://github.com/jprochazka/adsb-exchange_setup/issues  
