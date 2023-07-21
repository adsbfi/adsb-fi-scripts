# adsb.fi feed client

- These scripts aid in setting up your current ADS-B receiver to feed [adsb.fi](https://adsb.fi/).
- This will not disrupt any existing feed clients already present.
- When setting up new feeders, a decoder such as [readsb](https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-installation-for-readsb) must be installed separately.

## 1: Find antenna coordinates and elevation

<https://www.freemaptools.com/elevation-finder.htm>

## 2: Install the feed client

```
curl -L -o /tmp/feed.sh https://adsb.fi/feed.sh
sudo bash /tmp/feed.sh
```

## 3: Use netstat to check that your feed is working
The feed IP for adsb.fi is 103.196.37.90

```
netstat -t -n | grep -E '30004|31090'
```
Expected Output:
```
tcp        0    182 localhost:43530     103.196.37.90:31090      ESTABLISHED
tcp        0    410 localhost:47332     103.196.37.90:30004      ESTABLISHED
```

## 4: Optional: Install [local interface](https://github.com/wiedehopf/tar1090) for your data

The interface will be available at http://192.168.X.XX/adsbfi  
Replace the IP address with the address of your Raspberry Pi.

Install / Update:
```
sudo bash /usr/local/share/adsbfi/git/install-or-update-interface.sh
```
Remove:
```
sudo bash /usr/local/share/tar1090/uninstall.sh adsbfi
```

### Update the feed client without reconfiguring

```
curl -L -o /tmp/update.sh https://raw.githubusercontent.com/adsbfi/adsb-fi-scripts/master/update.sh
sudo bash /tmp/update.sh
```

### If you encounter issues, please do a reboot and then supply these logs on Discord (last 20 lines for each is sufficient):

```
sudo journalctl -u adsbfi-feed --no-pager
sudo journalctl -u adsbfi-mlat --no-pager
```

### Display the configuration

```
cat /etc/default/adsbfi
```

### Use an external source

If your feeder is on a separate device from the one this script is installed.
Edit `/etc/default/adsbfi` and change the IP on the following lines to point to your feeder device's IP:

```
INPUT="127.0.0.1:30005"
...
UAT_INPUT="127.0.0.1:30978"
```

### Changing the configuration

This is the same as the initial installation.
If the client is up to date it should not take as long as the original installation,
otherwise this will also update the client which will take a moment.

```
curl -L -o /tmp/feed.sh https://raw.githubusercontent.com/adsbfi/adsb-fi-scripts/master/install.sh
sudo bash /tmp/feed.sh
```

### Disable / Enable adsb.fi MLAT-results in your main decoder interface (readsb / dump1090-fa)

This is enabled by default. You probably don't need to change that.

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

### Restart the feed client

```
sudo systemctl restart adsbfi-feed
sudo systemctl restart adsbfi-mlat
```

### Show status

```
sudo systemctl status adsbfi-feed
sudo systemctl status adsbfi-mlat
```

### Removal / disabling the services

```
sudo bash /usr/local/share/adsbfi/uninstall.sh
```

If the above doesn't work, you can just disable the services and the scripts won't run anymore:

```
sudo systemctl disable --now adsbfi-feed
sudo systemctl disable --now adsbfi-mlat
```
