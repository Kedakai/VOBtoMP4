#!/bin/bash

working_path=$(pwd)
exclude_if_already_boxed=true
folgencount=0

function print_help() {
        echo "Dies eine Hilfe."
        echo "Das Skript MUSS im gleichen Ordner liegen wie alle Filmordner."
        echo "Bspw: VIDEO: /home/Video/Tet, /home/Video/Alex   SKRIPT: /home/Video/gettomp4.sh"
        echo 'Es eine Variable mit dem Namen: $exclude_if_already_boxed, welche im Skript auf true oder false gesetzt wird.'
        echo "Diese Variable bewirkt folgendes:"
        echo ""
        echo ""
        echo 'Diese Variable bestimmt ob Filme/Serien zu denen bereits MP4 Dateien gefunden werden, nochmals gepackt werden sollen'
        echo 'Bitte legen sie diese Variable im Skript fest.'
        echo 'Falls sie wollen, dass alle Filme neu gepackt werden, jedes mal, wenn das Skript gestartet wird, setzen sie die Variable auf "false".'
        echo 'Den gegenteiligen Effekt erzeugen sie mit dem Wert "true"'
        echo ""
        echo ""
        echo 'Mit -v oder --verbose ist ein ausführlicher Output möglich'
        echo 'Mit -h oder --help wird diese Hilfe angezeigt'
        echo 'Mit --delete ist es möglich Dateien nach dem Packen in eine MP4 sicher zu löschen. Dies funktioniert nur'
        echo 'wenn die Variable $exclude_if_already_boxed auf true gesetzt ist.'
}
function check_debug() {
        message="$1"
        if [ "$debug" = "1" ]; then
                echo "$message"
        fi
}

while [ "$1" != "" ];
do
    case $1 in
   -v  | --verbose )      debug=1
                ;;
   --delete )             delete=true
                ;;
   -h  | --help )         print_help
                          exit
                ;;
   *)                     print_help
                          echo "The parameter $1 is not allowed"
                          exit 1 # error
                ;;
    esac
    shift
done


if [ ! -f `which ffmpeg` ]; then
        echo "ffmpeg ist nicht installiert"
        echo "JA, ICH WEISS!"
        echo "Ciao"
        exit 4
else 
        check_debug "ffmpeg installiert"
fi

if ([ ! -x $exclude_if_already_boxed ] || ( [ "$exclude_if_already_boxed" != "true" ] && [ "exclude_if_already_boxed" = "false" ])); then
        echo 'Die Variable $exclude_if_already_boxed ist nicht richtig gesetzt'
        echo 'Diese Variable bestimmt ob Filme/Serien zu denen bereits MP4 Dateien gefunden werden, nochmals gepackt werden sollen'
        echo 'Bitte legen sie diese Variable im Skript fest.'
        echo 'Falls sie wollen, dass alle Filme neu gepackt werden, jedes mal, wenn das Skript gestartet wird, setzen sie die Variable auf "false".'
        echo 'Den gegenteiligen Effekt erzeugen sie mit dem Wert "true"'
else
        check_debug "Variable [exclude_if_already_boxed] richtig gesetzt"
fi

echo "Skript liegt aktuell in $working_path. Das Skript wird alles in diesem Ordner scannen und gemäß Einstellungen in eine MP4 umpacken."
echo "IST IHNEN IHR VORGEHEN BEWUSST??"
sleep 2
echo "Enter drücken zum Fortfahren. Pfad der uneingeschränkten Arbeit: $working_path"
read

if [ "$exclude_if_already_boxed" = "true" ]; then
        check_debug "Benutze Modus mit Berücksichtigung vorhandener Dateien"
        OIFS="$IFS"
        IFS=$'\n'
        for ordner in $(find $working_path/** | grep -v 'gettomp4.sh' | grep -v _TS); do
                check_debug "Bearbeite Ordner: $ordner"
                ordnername=$(echo $ordner | tr '/' '\n' | tail -n1)
                check_debug "Der Ordnername des aktuellen Ordners lautet: $ordnername"
                folgenanzahl=$(find $ordner/VIDEO_TS/* | grep -i vob | tr '/' '\n' | tail -n1 | cut -d '_' -f 1,2 | uniq | wc -l)
                check_debug "Im Ordner sind so viele Folgen vorhanden: $folgenanzahl"
                for folgen in $(find $ordner/VIDEO_TS/* | grep -i vob | tr '/' '\n' | tail -n1 | cut -d '_' -f 1,2 | uniq); do
                        check_debug "Folgende folge wurde erkannt: $folgen"
                        folgencount=$(( $folgencount + 1 ))
                        check_debug "Aktuell wird Folge: $folgencount bearbeitet."
                        if [ "$folgenanzahl" = "1" ]; then
                                folgenname=$(echo "$ordner/VIDEO_TS/$ordnername.mp4")
                        else
                                folgenname=$(echo "$ordner/VIDEO_TS/$ordnername_$folgencount.mp4")
                        fi
                        if [ ! -f "$folgenname" ]; then
                                find $ordner/VIDEO_TS/*
                                filecount=$(find $ordner/VIDEO_TS/* | grep -i $folgen | grep -i -c vob)
                                check_debug "Die Folge hat so viele Folgenteile: $filecount"
                                i="0"
                                while [ $i -lt $filecount ]; do
                                        i=$(( $i + 1 ))
                                        if [ -z ${parts+x} ]; then
                                                parts="$ordner/VIDEO_TS/${folgen}_${i}.VOB"
                                        else
                                                parts="$parts|$ordner/VIDEO_TS/${folgen}_${i}.VOB"
                                        fi
                                done
                                check_debug "Liste der Parts ist folgende: $parts"
                                check_debug "Beginnt Umpacken der Folge $folgenname"
                                ffmpeg -fflags +genpts -i concat:"$parts" -c:v copy -c:a copy -map 0:v:0 -map 0:a $folgenname > /dev/null 2>&1
                                rc=$?
                                if [ "$rc" = "0" ] && [ "$delete" = "true" ]; then
                                        check_debug "Prüfe die Itegrität von Folge: $folgencount"
                                        if [ "$(( `du -sc $ordner/VIDEO_TS/${folgen}*.VOB | tail -n 1 | tr '\t' ' ' | cut -d ' ' -f 1` - 200000 ))" -gt "$(du -sc $folgenname | grep insges | tr '\t' ' ' | cut -d ' ' -f 1 )" ]; then
                                                echo "$Ordner Folge Nummer: $folgencount WIRD NICHT GELÖSCHT. MANUELL PRÜFEN!"
                                        else
                                                check_debug "LÖSCHEN der Dateien gestartet."
                                                find "$ordner/VIDEO_TS/"${folgen}*.VOB -delete 
                                        fi
                                fi
                        fi
                        unset parts
                        filecount=0
                done
                folgencount=0
        done
else
        check_debug "Benutze Modus OHNE Berücksichtigung vorhandener Dateien"
        OIFS="$IFS"
        IFS=$'\n'
        for ordner in $(find $working_path/** | grep -v 'gettomp4.sh' | grep -v _TS); do
                check_debug "Bearbeite Ordner: $ordner"
                ordnername=$(echo $ordner | tr '/' '\n' | tail -n1)
                check_debug "Der Ordnername des aktuellen Ordners lautet: $ordnername"
                folgenanzahl=$(find $ordner/VIDEO_TS/* | grep -i vob | tr '/' '\n' | tail -n1 | cut -d '_' -f 1,2 | uniq | wc -l)
                check_debug "Im Ordner sind so viele Folgen vorhanden: $folgenanzahl"
                for folgen in $(find $ordner/VIDEO_TS/* | grep -i vob | tr '/' '\n' | tail -n1 | cut -d '_' -f 1,2 | uniq); do
                        check_debug "Folgende folge wurde erkannt: $folgen"
                        folgencount=$(( $folgencount + 1 ))
                        check_debug "Aktuell wird Folge: $folgencount bearbeitet."
                        if [ "$folgenanzahl" = "1" ]; then
                                folgenname=$(echo "$ordner/VIDEO_TS/$ordnername.mp4")
                        else
                                folgenname=$(echo "$ordner/VIDEO_TS/$ordnername_$folgencount.mp4")
                        fi
                        find $ordner/VIDEO_TS/*
                        filecount=$(find $ordner/VIDEO_TS/* | grep -i $folgen | grep -i -c vob)
                        check_debug "Die Folge hat so viele Folgenteile: $filecount"
                        i="0"
                        while [ $i -lt $filecount ]; do
                                i=$(( $i + 1 ))
                                if [ -z ${parts+x} ]; then
                                        parts="$ordner/VIDEO_TS/${folgen}_${i}.VOB"
                                else
                                        parts="$parts|$ordner/VIDEO_TS/${folgen}_${i}.VOB"
                                fi
                        done
                        check_debug "Liste der Parts ist folgende: $parts"
                        check_debug "Beginnt Umpacken der Folge $folgenname"
                        ffmpeg -y -fflags +genpts -i concat:"$parts" -c:v copy -c:a copy -map 0:v:0 -map 0:a $folgenname
                        unset parts
                        filecount=0
                done
                folgencount=0
        done
fi
