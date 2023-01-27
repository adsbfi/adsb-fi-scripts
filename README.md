# ADS-B.FI feed client

- These scripts aid in setting up your current ADS-B receiver to feed ADS-B.FI.
- They will not disrupt any existing feed clients already present

## 1: Find coordinates / elevation:

<https://www.freemaptools.com/elevation-finder.htm>

## 2: Install the adsbfi feed client

```
curl -L -o /tmp/axfeed.sh https://raw.githubusercontent.com/d4rken/adsb-fi-scripts/master/install.sh
sudo bash /tmp/axfeed.sh
```

## 3: Check these two URLs to check if your feed is working

- <https://www.adsb.fi/myip>
- <https://map.adsb.fi/mlat-map>

### Update the feed client without reconfiguring

```
curl -L -o /tmp/axupdate.sh https://raw.githubusercontent.com/d4rken/adsb-fi-scripts/master/install-or-update-interface.sh
sudo bash /tmp/axupdate.sh
```


### If you encounter issues, please do a reboot and then supply these logs on the forum (last 20 lines for each is sufficient):

```
sudo journalctl -u adsbfi-feed --no-pager
sudo journalctl -u adsbfi-mlat --no-pager
```


### Display the configuration

```
cat /etc/default/adsbfi
```

### Changing the configuration

This is the same as the initial installation.
If the client is up to date it should not take as long as the original installation,
otherwise this will also update the client which will take a moment.

```
curl -L -o /tmp/axfeed.sh https://raw.githubusercontent.com/d4rken/adsb-fi-scripts/master/install.sh
sudo bash /tmp/axfeed.sh
```

### Disable / Enable adsb.fi MLAT-results in your main decoder interface (readsb / dump1090-fa)

- Disable:

```
sudo sed --follow-symlinks -i -e 's/RESULTS=.*/RESULTS=""/' /etc/default/adsbfi
sudo systemctl restart adsbfi-mlat
```
- Enable:

```
sudo sed --follow-symlinks -i -e 's/RESULTS=.*/RESULTS="--results beast,connect,127.0.0.1:30104"/' /etc/default/adsbfi
sudo systemctl restart adsbfi-mlat
```

### Restart

```
sudo systemctl restart adsbfi-feed
sudo systemctl restart adsbfi-mlat
```


### Systemd Status

```
sudo systemctl status adsbfi-mlat
sudo systemctl status adsbfi-feed
```


### Removal / disabling the services:

```
sudo bash /usr/local/share/adsbfi/uninstall.sh
```

If the above doesn't work, you may be using an old version that didn't have the uninstall script, just disable the services and the scripts won't run anymore:

```
sudo systemctl disable --now adsbfi-feed
sudo systemctl disable --now adsbfi-mlat
```
