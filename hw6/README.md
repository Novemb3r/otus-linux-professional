# Домашнее задание 6

### Создать свой RPM

- Выкачиваем исходники
```
# wget https://yum.oracle.com/repo/OracleLinux/OL7/developer/nodejs12/x86_64/getPackageSource/nodejs-12.22.9-1.0.1.el7.src.rpm
```

```
# rpm -ihv --nosignature nodejs-12.22.9-1.0.1.el7.src.rpm
```

- Ставим зависимости

```
# yum-builddep nodejs.spec
Failed to set locale, defaulting to C
Loaded plugins: fastestmirror
Enabling base-source repository
Enabling extras-source repository
Enabling updates-source repository
Loading mirror speeds from cached hostfile
 * base: ftp.nsc.ru
 * extras: ftp.nsc.ru
 * updates: mirror.surf
Checking for new repos for mirrors
Getting requirements for nodejs.spec
 --> scl-utils-20130529-19.el7.x86_64
 --> Already installed : python-2.7.5-88.el7.x86_64
Error: No Package found for devtoolset-7-gcc >= 6.7
Error: No Package found for devtoolset-7-gcc-c++ >= 6.7
```

- Добавляем репу и ставим зависимости еще раз
```
# yum install centos-release-scl-rh
# yum-builddep nodejs.spec
```

- Собираем пакет 
```
# rpmbuild -bb nodejs.spec
```

- Устанавливаем
```
# yum install ./nodejs-12.22.9-1.0.1.el7.x86_64.rpm
```

- Проверяем
```
# node -v
v12.22.9
```
### Создать свой repo

```
# mkdir /home/repo && cd /home/repo
# createrepo .
# cp /root/rpmbuild/SPECS/nodejs-12.22.9-1.0.1.el7.x86_64.rpm repodata/
```

- Ставим nginx
```
# wget https://nginx.org/packages/rhel/7/x86_64/RPMS/nginx-1.14.2-1.el7_4.ngx.x86_64.rpm
# yum install ./nginx-1.14.2-1.el7_4.ngx.x86_64.rpm
# systemctl status nginx
● nginx.service - nginx - high performance web server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Ср 2022-02-23 11:32:28 UTC; 3s ago
```

- Правим default.conf nginx, добавляем autoindex, рестартим
- Добавляем конфиг репы
```
# cat /etc/yum.repos.d/hw.repo
[hwrepo]
name=HW-REPO
baseurl=http://127.0.0.1/repo/
enable=1
gpgcheck=0
skip_if_unavailable = 1
keepcache = 0
```

- Устанавливаем и проверяем
```
# yum install nodejs
Package nodejs-12.22.9-1.0.1.el7.x86_64 already installed and latest version
```
