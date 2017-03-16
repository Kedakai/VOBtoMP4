#!/bin/bash

working_path=$(pwd)
exclude_if_already_boxed=true
folgencount=0

function print_help() {
        echo "This is a help."
        echo "The script has to be installed in the same folder where all movie folders are."
        echo "ex: VIDEO: /home/Video/Tet, /home/Video/Alex   SCRIPT: /home/Video/gettomp4-eng.sh"
        echo 'There is the variable: $exclude_if_already_boxed, which can be set to true or false.'
        echo "This variable does the following:"
        echo ""
        echo ""
        echo 'The variable controls, if there is any mp4 found related to the VIDEO_TS folder of a movie, if it should repack the movie/series.'
        echo 'Please set the variable to either true or false.'
        echo 'If you want, that all movies/series that are found, should be repacked set variable to false.'
        echo 'If you want the opposite set it to "true"'
        echo ""
        echo ""
        echo 'With -v or --verbose it is possible to print debug information.'
        echo 'With -h or --help this help will be printed.'
        echo 'With --delete it is possible to SAFELY remove the packed files.'
        echo 'This only works if  $exclude_if_already_boxed is set to true.'
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
        echo "ffmpeg is not installed"
        echo "YES, I KNOW!"
        echo "Ciao"
        exit 4
else 
        check_debug "ffmpeg is installed"
fi

if ([ ! -x $exclude_if_already_boxed ] || ( [ "$exclude_if_already_boxed" != "true" ] && [ "exclude_if_already_boxed" = "false" ])); then
        echo 'The variable $exclude_if_already_boxed is'nt set right.'
        echo 'The variable controls, if there is any mp4 found related to the VIDEO_TS folder of a movie, if it should repack the movie/series.'
        echo 'Please set the variable to either true or false.'
        echo 'If you want, that all movies/series that are found, should be repacked set variable to false.'
        echo 'If you want the opposite set it to "true"'
else
        check_debug "Variable [exclude_if_already_boxed] set in the right way"
fi

echo "Script lays in  $working_path. The Skript will scan everything in this folder and repack movies/series to MP$ files."
echo "ARE YOU SURE WHAT YOU ARE DOING??"
sleep 2
echo "Please press enter to procced. Working-Path: $working_path"
read

if [ "$exclude_if_already_boxed" = "true" ]; then
        check_debug "Use Mode with mp4 recognition."
        OIFS="$IFS"
        IFS=$'\n'
        for ordner in $(find $working_path/** | grep -v 'gettomp4.sh' | grep -v _TS); do
                check_debug "Working on directory: $ordner"
                ordnername=$(echo $ordner | tr '/' '\n' | tail -n1)
                check_debug "The current folder is: $ordnername"
                folgenanzahl=$(find $ordner/VIDEO_TS/* | grep -i vob | tr '/' '\n' | tail -n1 | cut -d '_' -f 1,2 | uniq | wc -l)
                check_debug "There are : $folgenanzahl in this folder"
                for folgen in $(find $ordner/VIDEO_TS/* | grep -i vob | tr '/' '\n' | tail -n1 | cut -d '_' -f 1,2 | uniq); do
                        check_debug "Part recognized: $folgen"
                        folgencount=$(( $folgencount + 1 ))
                        check_debug "Processing part: $folgencount"
                        if [ "$folgenanzahl" = "1" ]; then
                                folgenname=$(echo "$ordner/VIDEO_TS/$ordnername.mp4")
                        else
                                folgenname=$(echo "$ordner/VIDEO_TS/$ordnername_$folgencount.mp4")
                        fi
                        if [ ! -f "$folgenname" ]; then
                                find $ordner/VIDEO_TS/*
                                filecount=$(find $ordner/VIDEO_TS/* | grep -i $folgen | grep -i -c vob)
                                check_debug "The part has: $filecount files"
                                i="0"
                                while [ $i -lt $filecount ]; do
                                        i=$(( $i + 1 ))
                                        if [ -z ${parts+x} ]; then
                                                parts="$ordner/VIDEO_TS/${folgen}_${i}.VOB"
                                        else
                                                parts="$parts|$ordner/VIDEO_TS/${folgen}_${i}.VOB"
                                        fi
                                done
                                check_debug "List of parts is following: $parts"
                                check_debug "Begin repack of part: $folgenname"
                                ffmpeg -fflags +genpts -i concat:"$parts" -c:v copy -c:a copy -map 0:v:0 -map 0:a $folgenname > /dev/null 2>&1
                                rc=$?
                                if [ "$rc" = "0" ] && [ "$delete" = "true" ]; then
                                        check_debug "Checking integrety of part: $folgencount"
                                        if [ "$(( `du -sc $ordner/VIDEO_TS/${folgen}*.VOB | tail -n 1 | tr '\t' ' ' | cut -d ' ' -f 1` - 200000 ))" -gt "$(du -sc $folgenname | grep insges | tr '\t' ' ' | cut -d ' ' -f 1 )" ]; then
                                                echo "$Ordner part number: $folgencount IS NOT GONNA BE DELETED. PLEASE CHECK MANUALLY."
                                        else
                                                check_debug "DELETE for part started."
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
        check_debug "User mode without regognition of existing files"
        OIFS="$IFS"
        IFS=$'\n'
        for ordner in $(find $working_path/** | grep -v 'gettomp4.sh' | grep -v _TS); do
                check_debug "Working on folder: $ordner"
                ordnername=$(echo $ordner | tr '/' '\n' | tail -n1)
                check_debug "The name of the current folder is: $ordnername"
                folgenanzahl=$(find $ordner/VIDEO_TS/* | grep -i vob | tr '/' '\n' | tail -n1 | cut -d '_' -f 1,2 | uniq | wc -l)
                check_debug "The current folder has that many parts: $folgenanzahl"
                for folgen in $(find $ordner/VIDEO_TS/* | grep -i vob | tr '/' '\n' | tail -n1 | cut -d '_' -f 1,2 | uniq); do
                        check_debug "Recognized following part: $folgen"
                        folgencount=$(( $folgencount + 1 ))
                        check_debug "Working on part: $folgencount"
                        if [ "$folgenanzahl" = "1" ]; then
                                folgenname=$(echo "$ordner/VIDEO_TS/$ordnername.mp4")
                        else
                                folgenname=$(echo "$ordner/VIDEO_TS/$ordnername_$folgencount.mp4")
                        fi
                        find $ordner/VIDEO_TS/*
                        filecount=$(find $ordner/VIDEO_TS/* | grep -i $folgen | grep -i -c vob)
                        check_debug "The part has that many files: $filecount"
                        i="0"
                        while [ $i -lt $filecount ]; do
                                i=$(( $i + 1 ))
                                if [ -z ${parts+x} ]; then
                                        parts="$ordner/VIDEO_TS/${folgen}_${i}.VOB"
                                else
                                        parts="$parts|$ordner/VIDEO_TS/${folgen}_${i}.VOB"
                                fi
                        done
                        check_debug "List of files are: $parts"
                        check_debug "Begin with repack of: $folgenname"
                        ffmpeg -y -fflags +genpts -i concat:"$parts" -c:v copy -c:a copy -map 0:v:0 -map 0:a $folgenname
                        unset parts
                        filecount=0
                done
                folgencount=0
        done
fi
