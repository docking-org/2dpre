#!/bin/bash
BINDIR=$(realpath $0)
BINDIR=$(dirname $BINDIR)

pg="psql -h n-1-17 -p 5534 -d zinc22_common -U zincuser"

function sync_up {
	order=$($pg --csv -c "select max(u_order)+1 from tin_upload_history" | tail -n 1)
        tail -n+2 $1 | while read line; do

                if [[ "$line" == "#"* ]]; then
			line=$(echo $line | tail -c+2 | sed 's/\\/\\\\/g' | sed "s/'/''/g" | sed "s/+/_/g")
                        [ -z $notes ] && notes="$line" || notes="$notes $line"

                else
                        function token {
                                echo "$1" | awk "{print \$$2}"
                        }
                        trans_id=$(token "$line" 1)
                        optype=$(token "$line" 2)
                        optional=$(token "$line" 3)
                        src=$(token "$line" 4)
                        diffdest=$(token "$line" 5)
                        options=$(token "$line" 6)

                        if [ "$optional" = "yes" ]; then
                                trans_id=$(echo $trans_id | head -c-2)
                                optional="true"
                        else
                                optional="false"
                        fi

			this_order=$($pg --csv -t -c "select u_order from tin_upload_history where transaction_id = '$trans_id'" | tail -n 1)
			if ! [ -z "$this_order" ]; then # we should be allowed to update whether an upload is optional or not, should the upload already exist
				$pg -c "update tin_upload_history set optional = $optional where u_order = $this_order"
			else
	                        $pg -c "insert into tin_upload_history(u_order, transaction_id, optype, optional, source, diffdest, options, notes) (values \
        	                        ($order, '$trans_id', '$optype', '$optional', '$src', '$diffdest', '$options', '$notes'))"
			fi
                        order=$((order+1))
			notes=

                fi

        done
}

function sync_down {
	printf "%24s %16s %8s %80s %32s %32s\n" TRANS_ID OPTYPE OPTIONAL SOURCE DIFFDEST OPTIONS > $1
        #echo -e "TRANS_ID\tOPTYPE\tOPTIONAL\tSOURCE\tDIFFDEST\tOPTIONS" > $1
        $pg -t -A -F'+' -c "select u_order, transaction_id, optype, optional, source, diffdest, options, notes from tin_upload_history order by u_order asc" | while read line; do
                function token {
                        echo $1 | cut -d'+' -f$2
                }
                trans_id=$(token "$line" 2)
		optype=$(token "$line" 3)
                optional=$(token "$line" 4)
                src=$(token "$line" 5)
                diffdest=$(token "$line" 6)
                options=$(token "$line" 7)
                notes=$(token "$line" 8)

		if [ "$optional" = "t" ]; then
			optional="yes"
			trans_id="$trans_id*"
		else
			optional="no"
		fi

		if ! [ -z "$notes" ]; then
	                echo $notes | while read line2; do
        	                echo "# $line2"
                	done
		fi

		printf "%24s %16s %8s %80s %32s %32s\n" $trans_id $optype $optional $src $diffdest $options
                #echo -e "$trans_id\t$optype\t$optional\t$src\t$diffdest\t$options"

        done >> $1
}

updown=$1
target=$2

if [ $updown = "up" ]; then

	sync_up $target

elif [ $updown = "down" ]; then

	sync_down $target

fi
