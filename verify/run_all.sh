#!/bin/bash

main="$1"
mkdir -p output
rm -rf output/*

POINTS=0

dir=`dirname "$1"`

errorslist=$dir/errors.out
rm -f $errorslist

cd "$dir"
if [ -f yarn.lock ];
then
	yarn || npm install
else
	npm install
fi

passed=0
failed=0
total=0

rm alfy.js

echo '{ "node":true, "loopfunc": true, "esnext":true }' > .jshintrc
if [ ! -f `basename "$1"` ];
then
	echo "Your main.js file is missing"
elif ! jshint *.js;
then
	echo "Please review your code, you have jshint errors"
elif ! jison alfy.jison -o alfy.js
then
	echo "Please review your jiosn file, you have errors"
else
	cd -

	for folder in alfy/*
	do
		if [ -d $folder ];
		then
			if [ -f "$folder"/run.txt ];
			then
				echo `head -n 1 "$folder"/run.txt`
				P=`head -n 2 "$folder"/run.txt | tail -n 1`
			else
				echo `basename $folder`
				P=10
			fi
			if [ $failed == 0 ] || ! (echo $folder | grep bonus &> /dev/null);
			then
				for file in "$folder"/*.alfy
				do
					inputfile=`pwd`/"$file"
					outputfile=output/`basename "$file"`.json
					originalfile="$file.json"
					errorsfile=output/`basename "$file"`.err
					title=`head -n 1 "$file" | grep '{' | cut -d '{' -f 2 | cut -d '}' -f 1` 
					if [ `echo -n "$title" | wc -c` -eq 0 ];
					then
						title=`basename $file`
					fi
					node "$1" "$inputfile" "$outputfile"
					strtitle="Verifying $title"
					printf '%s' "$strtitle"
					pad=$(printf '%0.1s' "."{1..60})
					padlength=70
					# echo $originalfile
					# echo $outputfile
					if node verify.js "$originalfile" "$outputfile" &> "$errorsfile"
					then
						str="ok (""$P""p)"
						passed=$(($passed+1))
						POINTS=$(($POINTS+$P))
					else
						diff --ignore-all-space -y --suppress-common-lines "$originalfile" "$outputfile" &> "$errorsfile" 
						str="error (0p)"
						failed=$(($failed+1))
						echo "--------------" >> $errorslist 
						echo $strtitle >> $errorslist
						# head -10 "$errorsfile" >> $errorslist
						cat "$errorsfile" >> $errorslist
					fi
					total=$(($total+1))
					printf '%*.*s' 0 $((padlength - ${#strtitle} - ${#str} )) "$pad"
				    printf '%s\n' "$str"
				done
			else
				echo "Not verifying bonus, you have $failed failed tests"
			fi
		fi
	done	
fi

echo 'Tests: ' $passed '/' $total
echo 'Points: '$POINTS
echo 'Mark without penalities: '`echo $(($POINTS * 2)) | sed 's/..$/.&/'`

if [ "$passed" != "$total" ];
then
	echo -e "Original tree						      | Your tree" 1>&2
	cat $errorslist 1>&2
fi
