#!/bin/bash

# convert 45degreee_fabric.png -matte -channel a -evaluate set 65% +channel 45degreee_fabric-65.png
opacity=$1;
if [ -z $opacity ]
then
	opacity=50
fi



# Create output directory
imgdir="../images/pattern-$opacity"
echo "Will write image to $imgdir"
mkdir -p $imgdir;

# Create sass file
scss="../scss"
mkdir -p $scss;
scss="../scss/pattern-$opacity.scss"
echo "Will write scss to $scss"
rm $scss

cat << 'SCSS' >> $scss
/* This file contain an example of using patterns with opacity $opacity */
.red { background-color: red; }
.green { background-color: green; }
.blue { background-color: blue; }
SCSS


# Create sample HTML files
webpage="../webpages"
mkdir -p $webpage;
webpage="../webpages/pattern-$opacity.html"
echo "Will write html to $webpage"
rm $webpage

cat << 'WEBPAGE' >> $webpage
<doctype html>
<head>
WEBPAGE
echo "<title>Opacity $opacity | Please choose a pattern</title>"	>> $webpage
echo "<link href='../css/pattern-$opacity.css' rel='stylesheet'/>"	>> $webpage

cat << 'WEBPAGE' >> $webpage
	<style>
		li.title { font-weight: bold; }
		li { list-style: none; padding: 1em; }
	</style>
</head>
<body>
WEBPAGE

for i in `ls ../images/patterns/*.png`; do
	j=`basename $i .png`;
	echo -n "Processing $j ... ";
	
	# Extract alpha channel with opacity you need...
	if [ ! -e $imgdir/$j.png ] 
	then
		convert $i -matte -channel a -evaluate set $opacity% +channel $imgdir/$j.png;
	fi
	
	# Write the scss file...
	echo ".$j { background-image: image-url(\"pattern-$opacity/$j.png\"); }" >> $scss

	# Write the webpage file...
	echo "<ul class='$j'>" >> $webpage
	echo "<li class='title'>$j</li>" >> $webpage
	echo "<li class='red $j'>Red</li>" >> $webpage
	echo "<li class='green $j'>Green</li>" >> $webpage
	echo "<li class='blue $j'>Blue</li>" >> $webpage
	echo "</ul>" >> $webpage

	echo "Done."
done;


cat << 'WEBPAGE' >> $webpage
</body>
<html>
WEBPAGE

tidy -m $webpage

