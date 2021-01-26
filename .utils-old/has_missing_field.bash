for src in /local2/load/H??P???_H??P???/src/*; do

	supplier=$src/supplier.txt

	if ! [ -f $supplier ]; then
		echo "supplier file not found in $src" 1>&2
		continue
	fi

	nf=$(head -n 1 $supplier | awk '{print NF}')
	if ! [ -z $nf ] && [ "$nf" -eq 2 ]; then
		echo $src
	fi
done
