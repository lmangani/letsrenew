# letsrenew
poorman's letsencrypt helper

### Example
```
./letsrenew.sh -d admin@domain.ext -d my.domain.ext
```

### Direct Drive 
```
./letsencrypt-auto certonly --webroot -w /var/www/vhosts/my.domain.ext/ -d my.domain.ext -d domain.ext
```
