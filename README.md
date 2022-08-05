# ADS-B Exchange feed client

- These scripts aid in setting up your current ADS-B receiver to feed ADS-B Exchange.
- They will not disrupt any existing feed clients already present

## 1: Find coordinates / elevation:

<https://www.freemaptools.com/elevation-finder.htm>

## 2: Install the adsbexchange feed client

```
curl -L -o /tmp/axfeed.sh https://adsbexchange.com/feed.sh
sudo bash /tmp/axfeed.sh
```

## 3: Check these two URLs to check if your feed is working

- <https://www.adsbexchange.com/myip>
- <https://map.adsbexchange.com/mlat-map>

## 4: Optional: Install the stats package for an online map that shows only planes received by you:

```
curl -L -o /tmp/axstats.sh https://adsbexchange.com/stats.sh
sudo bash /tmp/axstats.sh

adsbexchange-showurl
```

### Optional: local interface for your data http://192.168.X.XX/adsbx

Install / Update:
```
sudo bash /usr/local/share/adsbexchange/git/install-or-update-interface.sh
```
Remove:
```
sudo bash /usr/local/share/tar1090/uninstall.sh adsbx
```

### Update the feed client without reconfiguring

```
curl -L -o /tmp/axupdate.sh https://adsbexchange.com/feed-update.sh
sudo bash /tmp/axupdate.sh
```


### If you encounter issues, please do a reboot and then supply these logs on the forum (last 20 lines for each is sufficient):

```
sudo journalctl -u adsbexchange-feed --no-pager
sudo journalctl -u adsbexchange-mlat --no-pager
```


### Display the configuration

```
cat /etc/default/adsbexchange
```

### Changing the configuration

This is the same as the initial installation.
If the client is up to date it should not take as long as the original installation,
otherwise this will also update the client which will take a moment.

```
curl -L -o /tmp/axfeed.sh https://github.com/adsbxchange/adsb-exchange/raw/master/install.sh
sudo bash /tmp/axfeed.sh
```

### Disable / Enable adsbexchange MLAT-results in your main decoder interface (readsb / dump1090-fa)

- Disable:

```
sudo sed --follow-symlinks -i -e 's/RESULTS=.*/RESULTS=""/' /etc/default/adsbexchange
sudo systemctl restart adsbexchange-mlat
```
- Enable:

```
sudo sed --follow-symlinks -i -e 's/RESULTS=.*/RESULTS="--results beast,connect,127.0.0.1:30104"/' /etc/default/adsbexchange
sudo systemctl restart adsbexchange-mlat
```

### Other device as a data source (networked standalone receivers):

https://github.com/adsbxchange/wiki/wiki/Datasource-other-device

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
sudo bash /usr/local/share/adsbexchange/uninstall.sh
```

If the above doesn't work, you may be using an old version that didn't have the uninstall script, just disable the services and the scripts won't run anymore:

```
sudo systemctl disable --now adsbexchange-feed
sudo systemctl disable --now adsbexchange-mlat
```
