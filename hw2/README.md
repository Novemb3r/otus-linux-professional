# Домашнее задание 2

###      

- За основу взят Vagrantfile отсюда: https://github.com/erlong15/otus-linux
- Добавляем еще дисков, вставляем в конфиг подобные секции

```ruby
        :sataX => {
            :dfile => './sataX.vdi',
            :size => 250,
            :port => X
        }
```

- Дописываем provision скрипт, который создает RAID0 из 6 дисков и отправляет 1 диск в spare
- В тот же скрипт, прописываем создание GPT раздела и 5 партиций, а так же их монтирование
- Поднимаем VM, ловим

```
 mdadm: spare-devices setting is incompatible with raid level 0
```

- Ну и ладно. Тогда переписываем скрипт на RAID10 из 6 дисков, 1 добавляем в spare и передергиваем провижн

```
$ vagrant provision
```

- Смотрим, что натворили

```bash
$ lsblk
NAME      MAJ:MIN RM   SIZE RO TYPE   MOUNTPOINT
sda         8:0    0    40G  0 disk
`-sda1      8:1    0    40G  0 part   /
sdb         8:16   0   250M  0 disk
`-md0       9:0    0   744M  0 raid10
  |-md0p1 259:0    0   147M  0 md
  |-md0p2 259:1    0 148.5M  0 md
  |-md0p3 259:2    0   150M  0 md
  |-md0p4 259:3    0 148.5M  0 md
  `-md0p5 259:4    0   147M  0 md
sdc         8:32   0   250M  0 disk
`-md0       9:0    0   744M  0 raid10
  |-md0p1 259:0    0   147M  0 md
  |-md0p2 259:1    0 148.5M  0 md
  |-md0p3 259:2    0   150M  0 md
  |-md0p4 259:3    0 148.5M  0 md
  `-md0p5 259:4    0   147M  0 md
sdd         8:48   0   250M  0 disk
`-md0       9:0    0   744M  0 raid10
  |-md0p1 259:0    0   147M  0 md
  |-md0p2 259:1    0 148.5M  0 md
  |-md0p3 259:2    0   150M  0 md
  |-md0p4 259:3    0 148.5M  0 md
  `-md0p5 259:4    0   147M  0 md
sde         8:64   0   250M  0 disk
`-md0       9:0    0   744M  0 raid10
  |-md0p1 259:0    0   147M  0 md
  |-md0p2 259:1    0 148.5M  0 md
  |-md0p3 259:2    0   150M  0 md
  |-md0p4 259:3    0 148.5M  0 md
  `-md0p5 259:4    0   147M  0 md
sdf         8:80   0   250M  0 disk
`-md0       9:0    0   744M  0 raid10
  |-md0p1 259:0    0   147M  0 md
  |-md0p2 259:1    0 148.5M  0 md
  |-md0p3 259:2    0   150M  0 md
  |-md0p4 259:3    0 148.5M  0 md
  `-md0p5 259:4    0   147M  0 md
sdg         8:96   0   250M  0 disk
`-md0       9:0    0   744M  0 raid10
  |-md0p1 259:0    0   147M  0 md
  |-md0p2 259:1    0 148.5M  0 md
  |-md0p3 259:2    0   150M  0 md
  |-md0p4 259:3    0 148.5M  0 md
  `-md0p5 259:4    0   147M  0 md
sdh         8:112  0   250M  0 disk
`-md0       9:0    0   744M  0 raid10
  |-md0p1 259:0    0   147M  0 md
  |-md0p2 259:1    0 148.5M  0 md
  |-md0p3 259:2    0   150M  0 md
  |-md0p4 259:3    0 148.5M  0 md
  `-md0p5 259:4    0   147M  0 md
```

```
$ cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sdg[6](S) sdf[5] sdh[4] sde[3] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/6] [UUUUUU]

unused devices: <none>
```

- Имитируем сбой одного из дисков

```
$ sudo mdadm /dev/md0 -f /dev/sde
mdadm: set /dev/sde faulty in /dev/md0
```

- Проверяем, что `sde` в сбое, а `sdg` переместился из spare

```
$ cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sdg[6] sdf[5] sdh[4] sde[3](F) sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/6] [UUUUUU]

unused devices: <none>
```

- Доламываем raid

```
$ sudo mdadm /dev/md0 -f /dev/sdf
mdadm: set /dev/sdf faulty in /dev/md0
```

```
$ cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sdg[6] sdf[5](F) sdh[4] sde[3](F) sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/5] [UUUUU_]

unused devices: <none>
```

- Удаляем зафейленые диски

```
$ sudo mdadm /dev/md0 -r /dev/sdf /dev/sde
mdadm: hot removed /dev/sdf from /dev/md0
mdadm: hot removed /dev/sde from /dev/md0
```

- Добавляем новые

```
$ sudo mdadm /dev/md0 -a /dev/sdf /dev/sde
mdadm: added /dev/sdf
mdadm: added /dev/sde
```

- Проверяем состояние raid массива

```
$ cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sde[8] sdf[7](S) sdg[6] sdh[4] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/6] [UUUUUU]

unused devices: <none>
```

- Пропишем собранный raid в конфиг

```
# mkdir /etc/mdadm/
# echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
# mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
# cat /etc/mdadm/mdadm.conf
DEVICE partitions
ARRAY /dev/md0 level=raid10 num-devices=6 metadata=1.2 spares=1 name=otuslinux:0 UUID=a8886835:8271b97b:f3282d40:9e39da2e
```