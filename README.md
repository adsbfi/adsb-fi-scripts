# ADS-B Exchange Setup Scripts :airplane:

These scripts aid in setting up your current ADS-B receiver to feed ADS-B Exchange.

### Obtaining And Using The Scripts

```
sudo bash -c "$(wget -nv -O - https://raw.githubusercontent.com/adsbxchange/adsb-exchange/master/install.sh)"
```

Alternatively running the following commands will download the contents of this repository and begin setup.

    sudo apt-get install git
    git clone https://github.com/adsbxchange/adsb-exchange.git
    cd adsb-exchange
    chmod +x setup.sh
    sudo ./setup.sh
    
**After completing the setup do not delete this repository.**

### Checking status

### Display MLAT config
```
cat /etc/default/adsbexchange
```

### Systemd Status
```
sudo systemctl status adsbexchange-mlat

sudo systemctl status adsbexchange-feed
```

### Restart
```
sudo systemctl restart adsbexchange-feed

sudo systemctl restart adsbexchange-mlat
```

### If you encounter issues, please supply these logs on the forum (last 20 lines for each is sufficient):

```
sudo journalctl -u adsbexchange-feed --no-pager
sudo journalctl -u adsbexchange-mlat --no-pager
```

### Removal / disabling the services:

```
sudo systemctl disable --now adsbexchange-feed
sudo systemctl disable --now adsbexchange-mlat
```
