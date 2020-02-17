# ADS-B Exchange Setup Scripts :airplane:

These scripts aid in setting up your current ADS-B receiver to feed ADS-B Exchange.

### Obtaining And Using The Scripts

Use this command to start the setup process:

```
sudo bash -c "$(wget -nv -O - https://raw.githubusercontent.com/adsbxchange/adsb-exchange/master/install.sh)"
```

Alternatively running the following commands will begin the setup process:

```
sudo apt-get install git
sudo rm adsb-exchange -rf
git clone https://github.com/adsbxchange/adsb-exchange.git
cd adsb-exchange
sudo bash setup.sh
```

### Checking status

### Display MLAT config
```
cat /etc/default/adsbexchange
```

### If you encounter issues, please supply these logs on the forum (last 20 lines for each is sufficient):

```
sudo journalctl -u adsbexchange-feed --no-pager
sudo journalctl -u adsbexchange-mlat --no-pager
```

### Restart

```
sudo systemctl restart adsbexchange-feed
sudo systemctl restart adsbexchange-mlat
```


### Systemd Status

```
sudo systemctl status adsbexchange-mlat
sudo systemctl status adsbexchange-feed
```


### Removal / disabling the services:

```
sudo systemctl disable --now adsbexchange-feed
sudo systemctl disable --now adsbexchange-mlat


--adsbx-git-discord
```
