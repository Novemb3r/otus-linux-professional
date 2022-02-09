# Домашнее задание 3

- За основу взят Vagrantfile отсюда: https://gitlab.com/otus_linux/stands-03-lvm/-/blob/master/Vagrantfile

#### Уменьшить том под / до 8G

- Eсли мы просто уменьшим через lvreduce /dev/VolGroup00/LogVol0, то, веротяно, это будет последнее, что мы сделаем на
  этой машине
- Глянем, какая там ФС

```
/dev/mapper/VolGroup00-LogVol00 on / type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
```

- Для начала добавим sdb в VG

```
# vgextend VolGroup00 /dev/sdb
```

- Создадим новый LV, куда потом перенесем систему

```
# lvcreate -L 8G -n LogVol02 VolGroup00
```

- Создаем файловую систему

```
# mkfs.xfs /dev/VolGroup00/LogVol02
```

- Монтируем

```
 mount /dev/VolGroup00/LogVol02 /mnt
```

- Промежуточный lsblk

```
# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
└─VolGroup00-LogVol02   253:2    0    8G  0 lvm  /mnt
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```

- Делаем дамп и рестор ФС

```
# xfsdump /dev/VolGroup00/LogVol00 -f /home/vagrant/fs
# xfsrestore -f /home/vagrant/fs /mnt/
```

- Самая скучная часть

```
# mount --bind /dev /mnt/dev && mount --bind /proc /mnt/proc && mount --bind /sys /mnt/sys && mount --bind /run /mnt/run && mount --bind /boot /mnt/boot/
```

- chroot в новую систему

```
# chroot /mnt
```

- Недолго пытаемся найти genfstab, но, видимо, не судьба, здесь вам не arch. Правим руками

```
# vi /etc/fstab
# vi /etc/default/grub
```

- Перегенериваем конфиг grub

```
# grub2-mkconfig -o /boot/grub2/grub.cfg
```

- Выходим из chroot, правим fstab, ребутаемся

```
# exit
# vi /etc/fstab
# reboot
```

- Кажется, сработало

```
$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0 37.5G  0 lvm
sdb                       8:16   0   10G  0 disk
└─VolGroup00-LogVol02   253:0    0    8G  0 lvm  /
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```

- Удалим старый LV

```
# lvremove /dev/VolGroup00/LogVol00
```

#### Выделить том под /home

- Выделяем, создаем fs

```
# lvcreate -L 5G -n LogVol00 VolGroup00
# mkfs.xfs /dev/VolGroup00/LogVol00      
```

- Прописываем в fstab

```
/dev/mapper/VolGroup00-LogVol00 /home			xfs	defaults 0 0
```

- Ребут

```
$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
|-sda1                    8:1    0    1M  0 part
|-sda2                    8:2    0    1G  0 part /boot
`-sda3                    8:3    0   39G  0 part
  |-VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  `-VolGroup00-LogVol00 253:2    0    5G  0 lvm  /home
sdb                       8:16   0   10G  0 disk
`-VolGroup00-LogVol02   253:0    0    8G  0 lvm  /
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```

#### /var - сделать в mirror

- Создаем PV

```
# pvcreate /dev/sdc /dev/sdd              
```

- Создаем VG

```
# vgcreate vg_var /dev/sdc /dev/sdd
```

- Создаем LV

```
# lvcreate -L 950M -m1 -n lv_var vg_var
```

- Делаем fs, синкуем файлы

```
# mkfs.xfs /dev/vg_var/lv_var
# mount /dev/vg_var/lv_var /mnt
# rsync -avHPSAX /var/ /mnt/
```

- Монтируем

```
# umount /mnt
# mount /dev/vg_var/lv_var /var
```

- Снова правим fstab и ребутаемся

```
$ lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk
|-sda1                     8:1    0    1M  0 part
|-sda2                     8:2    0    1G  0 part /boot
`-sda3                     8:3    0   39G  0 part
  |-VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
  `-VolGroup00-LogVol00  253:2    0    5G  0 lvm  /home
sdb                        8:16   0   10G  0 disk
`-VolGroup00-LogVol02    253:0    0    8G  0 lvm  /
sdc                        8:32   0    2G  0 disk
|-vg_var-lv_var_rmeta_0  253:3    0    4M  0 lvm
| `-vg_var-lv_var        253:7    0  952M  0 lvm  /var
`-vg_var-lv_var_rimage_0 253:4    0  952M  0 lvm
  `-vg_var-lv_var        253:7    0  952M  0 lvm  /var
sdd                        8:48   0    1G  0 disk
|-vg_var-lv_var_rmeta_1  253:5    0    4M  0 lvm
| `-vg_var-lv_var        253:7    0  952M  0 lvm  /var
`-vg_var-lv_var_rimage_1 253:6    0  952M  0 lvm
  `-vg_var-lv_var        253:7    0  952M  0 lvm  /var
sde                        8:64   0    1G  0 disk
```

#### /home - сделать том для снэпшотов

- Генерим кучку файлов

```
# touch /home/file{1..20}
```

- Делаем снапшот

```
# lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol00
```

- Удаляем файлы

```
# rm -f /home/file{11..20}
# ls | wc -l
11
```

- Восстанавливаемся (здесь немного неописаных сложностей с тем, чтобы отмонтировать /home/)

```
# umount /home
# lvconvert --merge /dev/VolGroup00/home_snap
# mount /home
# ls | wc -l
21
```

#### Ставим zfs

- Ставим zfs :)

```
# yum install http://download.zfsonlinux.org/epel/zfs-release.el7_6.noarch.rpm 
# yum install epel-release.noarch -y                                           
# gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux       
# yum install kernel-devel zfs          
# reboot  
```

```
# modprobe zfs
modprobe: FATAL: Module zfs not found.
```

- Классика, ничего не встало, делаем

```
# dkms build -m zfs -v 0.7.13 --kernelsourcedir /usr/src/kernels/3.10.0-1160.53.1.el7.x86_64
# dkms install -m zfs -v 0.7.13
# reboot
```

- Создаем zpool, монтируем

```
# zpool create zopt mirror /dev/sdd /dev/sde cache /dev/sdc
# zfs set mountpoint=/opt zopt
# zfs mount zopt
# zpool status
 ```

```
zfs set mountpoint=/opt zopt 
zfs mount zopt
```

- Делаем файлик и его снапшот

```
# touch somefile
# zfs snapshot -r zopt@snap
# rm -rf /opt/somefile
```

- Восстанавливаемся

```
# zfs rollback zopt@snap
# ls /opt                    
somefile       
```