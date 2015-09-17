#!/bin/bash

#Проверяем наличие и количество аргументов
echo
[ "$#" -ne 1 ] && echo "Wrong number of arguments"

# Запускаем файл на исполнение $./import_inv_net.sh -[options], при условии что в том же каталоге находится файл со списком станций которые нужно добавить с именем sta_add 
# options:
#	-a (append) : добавляет станции перечисленные в файле sta_add
#	-d (delete) : удаляет станции перечисленные в файле sta_add
#	-da (delete) : удаляет все станции
#	-r (replace): добавляет станции перечисленные в файле sta_add, сначала удаляя весь имеющийся инвентори
#	-n (networks append): добавляет сети станций перечисленные в файле sta_add
prog=$0

#Устанавливаем путь к инвентори файлам каждой станции, которые будут добавлены, которые разбиты по своим сетям
export INV_PATH=${HOME}/inventory/metadata
#export INV_PATH=${HOME}/Downloads/inventory/metadata

#Устанавливаем путь к существующим инвентори файлам каждой станции
export EXIST_INV_PATH=${HOME}/seiscomp3/etc/inventory

#Устанавливаем путь к директории где будут храниться профайлы для каждой станции
export KEY_PATH=${HOME}/seiscomp3/etc/key

#Читаем файл со списком станций на добавление/удаление: sta_add
if [ -f /tmp/sta_add ]; then 
line=$(cat /tmp/sta_add)
else echo "Station file \"sta_add\" does not exist! Program terminated."; exit;
fi

#Функция добавления сети станций в seiscomp
net_add(){
seiscomp stop
#Проходимся по списку сетей станций указанних в файле sta_add (Сетей может бить несколько)
for n in $line; do

#Заполняем массив array именами инвентори файлов для одной сети с полным путем к ним
array=($(ls $INV_PATH/$n/*StationXML))

#Заполняем массив nets массивами array и получаем полнй список инвентори файлов находящихся в разних сетях
nets="$nets ${array[*]}"
done

#Проходим по списку всех станций всех сетей
for i in ${nets[*]}
do

#Получаем имя сети и станции
net_sta=($(echo $i | awk -F\/ '{print $7}' | sed s/.StationXML//g))
#################################
#Формируем путь к инвентори файлу соотвествующей станции
sta_path=$i;
#Подключаем инвентори файл станции к сейскомпу
seiscomp exec import_inv fdsnxml $sta_path;

#Создаем ключевой файл с указанием привязанных к станции модулей seedlink autopick
#соотвественно seedlink определяет будут ли закачиваться данные и autopick 
#определяет будет ли данная станция учавствовать в обнаружении сигналов. 
#пример имени файла ${HOME}/seiscomp3/etc/key/station_GE_APE
echo '# Binding references
scautopick:autopick
seedlink:seedlink' > $KEY_PATH/station_$net_sta;
done;
}

#Функция добавления станций в seiscomp
add(){
seiscomp stop
#Проходимся по списку станций
for i in $line; do
#Выделяем имя сети
network_name=$(echo $i | awk -F_ '{print $1}');
#Формируем путь к инвентори файлу соотвествующей станции
sta_path=$INV_PATH/$network_name/$i.StationXML;
#Подключаем инвентори файл станции к сейскомпу
seiscomp exec import_inv fdsnxml $sta_path;

#Создаем ключевой файл с указанием привязанных к станции модулей seedlink autopick
#соотвественно seedlink определяет будут ли закачиваться данные и autopick 
#определяет будет ли данная станция учавствовать в обнаружении сигналов. 
#пример имени файла ${HOME}/seiscomp3/etc/key/station_GE_APE
echo '# Binding references
scautopick:autopick
seedlink:seedlink' > $KEY_PATH/station_$i;
done;
}

#Функция удаления станций перечисленних в файле /tmp/sta_add
del_sta(){
seiscomp stop
#Проходимся по списку станций
for i in $line; do
#Выделяем имя сети
network_name=$(echo $i | awk -F_ '{print $1}');
#Формируем путь к инвентори файлу соотвествующей станции
sta_path=$EXIST_INV_PATH/$i.StationXML.xml;
#Удалаяем инвентори файл станции из сейскомпа
rm $sta_path 2>/dev/null;
RETVAL=$?;
echo
[ $RETVAL = 0 ] && echo "Station deleted" || echo "There're no stations to be deleted"
echo

done;
}


#Функция удаления всех станций из каталога $HOME/seiscomp3/etc/inventory/
del_all(){
seiscomp stop
rm $EXIST_INV_PATH/* 2>/dev/null
RETVAL=$?
echo
[ $RETVAL = 0 ] && echo "Stations deleted" || echo "There're no stations to be deleted"
echo
}

case "$1" in

-n)	
	net_add
	seiscomp update-config inventory
	;;

-a)
	add
	seiscomp update-config inventory
	;;

-r)
	del_all
	seiscomp update-config inventory
	add
	seiscomp update-config inventory
	;;

-d)	
	del_sta
	seiscomp update-config inventory
	;;

-da)	
	del_all
	seiscomp update-config inventory
	;;
*)
echo
echo $"Usage: $prog {-a||-d||-da||-r||-n}"
echo
exit 1
esac

seiscomp update-config
seiscomp restart

