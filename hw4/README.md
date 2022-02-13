# Домашнее задание 4

### Определить алгоритм с наилучшим сжатием

- Понимаем vm с пачкой дисков

```
# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   64G  0 disk
|-sda1   8:1    0  2.1G  0 part [SWAP]
`-sda2   8:2    0 61.9G  0 part /
sdb      8:16   0    1G  0 disk
sdc      8:32   0    1G  0 disk
sdd      8:48   0    1G  0 disk
sde      8:64   0    1G  0 disk
sdf      8:80   0    1G  0 disk
sdg      8:96   0    1G  0 disk
sdh      8:112  0    1G  0 disk
sdi      8:128  0    1G  0 disk
```

- Создаем 4 пула с разными алгоритмами сжатия

```
# zpool create z1 mirror /dev/sdb /dev/sdc
# zpool create z2 mirror /dev/sdd /dev/sde
# zpool create z3 mirror /dev/sdf /dev/sdg
# zpool create z4 mirror /dev/sdh /dev/sdi
# zfs set compression=lzjb z1
# zfs set compression=lz4 z2
# zfs set compression=gzip-9 z3
# zfs set compression=zle z4
# zfs get all | grep compression
z1    compression           lzjb                   local
z2    compression           lz4                    local
z3    compression           gzip-9                 local
z4    compression           zle                    local
```

- Качаем исходники ядра

```
# wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.16.9.tar.gz
# tar -xzf linux-5.16.9.tar.gz
# du -sh ./*
1.2G	./linux-5.16.9
```

- На /dev/sda (xfs) они весят 1.2G. Копируем в каждый пул, замеряя время

```
# for i in {1..4}; do time cp -r ./linux-5.16.9 /z$i/; done

real	0m59.560s
user	0m0.577s
sys	    0m18.225s

real	0m57.546s
user	0m0.772s
sys	    0m18.052s

real	1m33.992s
user	0m0.271s
sys	    0m18.405s

real	1m2.818s
user	0m0.610s
sys	    0m16.687s
```

- Проведя эксперимент несколько раз, можем заметить, что все алгоритмы, кроме gzip-9 выполняют копирование примерно за
  одинаковое время. gzip-9 справляется хуже примерно в 1,5 раза

- Посмотрим на занимаемый размер

```
# zfs list
NAME   USED  AVAIL     REFER  MOUNTPOINT
z1     477M   355M      475M  /z1
z2     417M   415M      415M  /z2
z3     273M   559M      272M  /z3
z4     832M   108K      831M  /z4

# zfs get all | grep compressratio | grep -v ref
z1    compressratio         2.55x                  -
z2    compressratio         2.93x                  -
z3    compressratio         4.58x                  -
z4    compressratio         1.09x                  -
```

Как можно заметить, gzip-9 сжимает файлы лучше, чем другие алгоритмы, однако, требует больше времени для операций.

### Определение настроек пула

- Скачиваем архив и распаковываем

```
# wget -O archive.tar.gz 'https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download
# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
```

- Импортируем пул

```
# zpool import -d zpoolexport/ otus
# zpool status
  pool: otus
 state: ONLINE
status: Some supported features are not enabled on the pool. The pool can
	still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
	the pool may no longer be accessible by software that does not support
	the features. See zpool-features(5) for details.
config:

	NAME                                 STATE     READ WRITE CKSUM
	otus                                 ONLINE       0     0     0
	  mirror-0                           ONLINE       0     0     0
	    /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
	    /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0
```

- Определяем настройки. Размер хранилища

```
# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
```

- Тип

```
# zfs get type otus
NAME  PROPERTY  VALUE       SOURCE
otus  type      filesystem  -
```

- Recordsize

```
# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
```

- Алгоритм сжатия

```
# zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local
```

- Алгоритм checksum

```
# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```

- Сохраним все настройки пула

```
# zfs get all otus > settings
```

### Найти сообщение от преподавателей

- Качаем снапшот

```
# wget -O otus_task2.file 'https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download'
```

- Восстанавливаемся

```
# cat otus_task2.file | zfs recv otus/res
```

- Ищем и читаем файл

```
# find /otus/res -name secret_message | xargs cat
https://github.com/sindresorhus/awesome
```