#!/bin/bash

# convert 45degreee_fabric.png -matte -channel a -evaluate set 65% +channel 45degreee_fabric-65.png
opacity=$1;
if [ -z $opacity ]
then
	opacity=50
fi

for i in `ls ../images/patterns/*.png`; do
	j=`basename $i .png`;
	outdir="../images/pattern-$opacity/"
	mkdir -p $outdir;
	convert $i -matte -channel a -evaluate set $opacity% +channel $outdir$j;
done;
