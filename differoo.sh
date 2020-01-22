#!/bin/bash

#Variables
USAGE="Type -h to see all switches and additional help"
SUSPECT=""
CLEAN=""
OUTDIR=""
QUIET=0

echo " ____  _ ___ ___                 ";
echo "|    \|_|  _|  _|___ ___ ___ ___ ";
echo "|  |  | |  _|  _| -_|  _| . | . |";
echo "|____/|_|_| |_| |___|_| |___|___|";
echo "          ";
echo " Version 1.0                     ";
echo " By Andreas Aaris-Larsen         ";
echo "          ";


#Commandline arguments
while [ "$1" != "" ]; do
        case $1 in
                -h | --help )           echo -e "Diff all the things!\r\nFeed it two mounted partitions (or folders) and it will md5sum all of them and compare the two.\r\nIntended for comparing a compromised box with a known-good box, to see what changed or went missing.\r\n"
					echo -e "\t -s | --suspect \t\t\t the mounted partition that has suspected changes)"
					echo -e "\t -c | --clean \t\t\t the mounted partition that is known-good)"
					echo -e "\t -o | --outdir \t\t\t where to store the output files"
                                        exit
                                        ;;
                -s | --suspect )        shift
                                        SUSPECT=$1
                                        ;;
                -c | --clean )          shift
                                        CLEAN=$1
                                        ;;
                -o | --outdir )         shift
                                        OUTDIR=$1
                                        ;;		
                -q | --quiet )          QUIET=1
                                        ;;										
                * )                     echo $USAGE
                                        exit 1
        esac
        shift
done

if [[ ! $SUSPECT ]]; then
        echo "Suspect (-s)must be set"
        exit 1
fi
if [[ ! $CLEAN ]]; then
        echo "Clean (-c) must be set"
        exit 1
fi
if [[ ! $OUTDIR ]]; then
        echo "Outdir (-o) must be set"
        exit 1
fi

starttime=`date +%s`
echo -e "\t + Creating hashes of all files on the suspect drive..."
sudo find $SUSPECT | while read line; do sudo md5sum $line 2>/dev/null ; done > $OUTDIR/suspect.txt
echo -e "\t + Creating hashes of all files on the known-good drive..."
sudo find $CLEAN | while read line; do sudo md5sum $line 2>/dev/null ; done > $OUTDIR/clean.txt
echo -e "\t + Comparing..."
echo -en "\t + Looking for altered files..."
cat $OUTDIR/suspect.txt | while read line
do
	if [ $QUIET -eq 1 ]; then
		if sudo grep -q $line $OUTDIR/clean.txt; then
			echo -n "." #do nothing
		else
			echo $line >> $OUTDIR/altered.txt
		fi
	fi
done
echo " "
echo -en "\t + Looking for missing files..."
cat $OUTDIR/clean.txt | while read line
do
	if [ $QUIET -eq 1 ]; then
		if sudo grep -q $line $OUTDIR/suspect.txt; then
			echo -n "." #do nothing
		else
			echo $line >> $OUTDIR/missing.txt
		fi
	fi
done
echo " "
if [ $QUIET -eq 0 ]; then
	echo -e "\t + These files were altered from the known-good:"
	cat $OUTDIR/altered.txt | while read line
	do
		echo -e "\t\t - " $line
	done
	
	echo -e "\t + These known-good files are missing:"
	cat $OUTDIR/missing.txt | while read line
	do
		echo -e "\t\t - " $line
	done
fi
if [ $QUIET -eq 1 ]; then
	echo "See the output folder for altered (altered.txt) and missing (missing.txt) files."
fi

endtime=`date +%s`
echo -e "\t - Completed in " $((endtime-starttime)) " seconds"
