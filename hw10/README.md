# Домашнее задание 10

### Попасть в систему без пароля несколькими способами

#### Способ 1

- Во время загрузки в GRUB жмем e, далее, после linux16 прописываем вместо `ro`

```
rw init=/sysroot/bin/sh
```

- Продолжаем загрузку, попадаем в систему

#### Способ 2

- Так же, как в прошлый раз, только дописываем rd.break
- sysroot не будет доступен на запись, поэтому перемонтируем

```
# mount -o remount,rw /sysroot
# chroot /sysroot
```

- Меняем пароль

```
# passwd root
```

- Вызываем автолелейбл при следующей загрузке

```
# touch /.autorelabel
```

- Ребутаемся, попадаем в систему

### Установить систему с LVM, после чего переименовать VG

- Смотрим текущее имя VG

```
# vgdisplay 
--- Volume group ---
VG Name               VolGroup00
```

- Переименовываем

```
# vgrename VolGroup00 VG00
Volume group "VolGroup00" successfully renamed to "VG00"
```

- Еще раз проверяем

```
# vgdisplay 
--- Volume group ---
VG Name               VG00
```

- Правим fstab и конфиг GRUB

```
/dev/mapper/VG00-LogVol00 /                       xfs     defaults        0 0
```

- Перегенерим initrd

```
# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
```

- Ребутаемся

### Добавить модуль в initrd

- Создаем папку с модулем

```
# mkdir /usr/lib/dracut/modules.d/01test
```

- В нее копируем пару файлов, правим test.sh

```
# cat test.sh
#!/bin/sh
exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
echo Hello world!
sleep 60
```

- Перегенерим initrd

```
# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
```

- Убираем из конфига GRUB `quiet`, перегенериваем, ребутаемся

- Видим в консоли `Hello world!` и ощущаем sleep :)