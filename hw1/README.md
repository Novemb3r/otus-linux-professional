# Домашнее задание 1

### Подготовка окружения для работы

- Проверяем установку virtualbox
```bash
$ virtualbox -h
Oracle VM VirtualBox Manager 5.2.42_Ubuntu
```

- Проверяем установку vagrant
```bash
$ vagrant -v
Vagrant 2.2.19
```

- Проверяем установку packer
```bash
$ packer -v
1.7.9
```

- Форкаем и клонируем репозиторий
```bash
git clone https://github.com/Novemb3r/manual_kernel_update.git
```

### Обновление ядра из репозитория

- Запускаем ВМ и подключаемся к ней
```bash
$ vagrant up
$ vagrant ssh
```

- Проверяем текущую версию ядра
```bash
$ uname -r
3.10.0-1127.el7.x86_64
```

- Подключаем репозиторий, устанавливаем новое ядро
```bash
$ sudo yum install -y http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
$ sudo yum --enablerepo elrepo-kernel install kernel-ml -y
```

- Обновляем конфиг GRUB и ребутаем ВМ
```bash
$ sudo grub2-mkconfig -o /boot/grub2/grub.cfg
$ sudo grub2-set-default 0
$ sudo reboot
```

- Еще раз подключаемся к ВМ после ребута
```bash
vagrant ssh
```

- Проверяем версию ядра
```bash
$ uname -r
5.16.3-1.el7.elrepo.x86_64
```

### Создание нового образа системы

- Запускаем packer
```bash
$ packer build centos.json
```

- Видим ошибку из за устаревшего формата конфига. Пробуем запустить packer fix, чтобы автоматически его исправить:
```bash
$ packer fix centos.json
```

- Копируем вывод команды в файл centos.json и снова запускаем packer
```bash
$ packer build centos.json
```

- Ловим ошибку
```bash
VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component MachineWrap, interface IMachine
```
Долгие мучения, в итоге, выяснил, что ошибка была из-за того, что при сборке запускалась gui, а я работал на удаленной машине через ssh (потому что m1)
Добавим параметр headless в конфиг, чтобы не запускать GUI

```JSON
{
    "builders": [
        {
            "headless": "true",
            
```

- Вновь собираем образ
```bash
$ packer build centos.json
```

- На этот раз успешно. Выполняем импорт:
```bash
$ vagrant box add --name centos-7-5 centos-7.7.1908-kernel-5-x86_64-Minimal.box
```

- Проверяем в списке:
```bash
$ vagrant box list
centos-7-5 (virtualbox, 0)
```

- Создаем новую папку и Vagrantfile в ней указываем
```
 :box_name => "centos-7-5",
```

- Запускаем, подключаемся, проверяем версию:
```bash
$ uname -r
5.16.3-1.el7.elrepo.x86_64
```

**NOTE**: во втором скрипте есть странный блок в конце
```bash
# Fill zeros all empty space
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
sync
grub2-set-default 1
echo "###   Hi from secone stage" >> /boot/grub2/grub.cfg
```
судя по всему, он должен откатить нас назад к старому ядру, но, видимо, скрипт не отрабатывает до конца:
```
centos-7.7: dd: error writing ‘/EMPTY’: No space left on device
```

странно, что в такой ситуации не заваливается сборка, кажется, не хватает ```set -e```

- Паблишим образ в Vagrant Cloud
```
$ vagrant cloud publish novemb3r/centos7-5 1.0 virtualbox ../packer/centos-7.7.1908-kernel-5-x86_64-Minimal.box --force --release
```

https://app.vagrantup.com/novemb3r/boxes/centos7-5

### Пересборка ядра из исходников

- Добавляем скрипт в packer/scripts, который делает всю работу. Ядро выберем весии 5.5, чтобы не мучаться пересборкой gcc из исходников (последняя версия gcc в репе - 4.8, пробовал собирать ядра 5.16 и 5.10 - хотят выше)
- Правим centos.json, добавляем наш скрипт вместо stage-1-kernel-update.sh, добавляем ядер и RAM, потому что жизнь и так короткая
- Запускаем packer build в скрине, чтобы сборка не прервалась
```
$ screen -R i.kutyrev
$ packer build
```

- Импортируем полученную ВМ, запускаем, проверяем версию ядра
```
$ uname -r
5.5.1
```