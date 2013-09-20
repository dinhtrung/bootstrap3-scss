#!/bin/bash

#########################################################################
## sudo apt-get install fontforge
## sudo apt-get install eot-utils
## wget http://mirrors.digipower.vn/apache/xmlgraphics/batik/batik-1.7.zip
## unzip batik-1.7.zip
## wget http://people.mozilla.com/~jkew/woff/woff-code-latest.zip
## unzip woff-code-latest.zip
## make
#########################################################################


BATIK_DIR='./batik-1.7'
#########################################################################
## PROGRAM AREA                                                         #
#########################################################################

FILE_STUBS=''
SCRIPT_DIR=`echo $0 | sed "s/convertFonts.sh//"`

IFS=$(echo -en "\n\b")

toTTF () {
	echo "(Using FontForge)"
	fontforge -script $SCRIPT_DIR/2ttf.pe $i 
}

toEOT () {
	echo "(Using mkeot)"
	FILE_STUB=`echo $NEW_FILE | 
		sed "s/\.[tT][tT][fF]$//" |
                    sed "s/\.[oO][tT][fF]$//"`
	mkeot $1 > $FILE_STUB.eot
}

toSVG() {
	if [ -f "$BATIK_DIR/batik-ttf2svg.jar" ]
	then 
	
		java -jar "$BATIK_DIR/batik-ttf2svg.jar"  \
			$1 -l 32 -h 127 -o $i.tmp -id $2 2> /dev/null

		cat $i.tmp | grep -v "<hkern" > $2.svg

		rm $i.tmp
	elif [ -f $SCRIPT_DIR/2svg.pe ]
	then
		fontforge -script $SCRIPT_DIR/2svg.pe $1
	else 
		echo "Error: cannot produce SVG font"
	fi
}

getFontName () { 
	if [ "fontforge_EXT" = "bat" ]
	then
		fontforge -script `cygpath -w $SCRIPT_DIR/getFontName.pe` \
			`cygpath $1` 2> /dev/null | tr ' ' '_'  |
			sed "s/
//g" 
	else
		fontforge -script $SCRIPT_DIR/getFontName.pe $1 2> /dev/null | tr ' ' '_' 
	fi
}





getSVGID () {
	grep "id=" $1 | tr ' ' '
' | grep ^id | awk -F'"' '{print $2}'
}

toWOFF () {
	./sfnt2woff/sfnt2woff $1
}

if [ "$#" -eq "0" ]
then
	echo "Usage: $0 <font list>" 1>&2
	exit 1
fi

# .. check to make sure all packages are installed
for i in java fontforge
do
	which $i > /dev/null 2> /dev/null
	if [ "$?" != "0" ]
	then
		echo "Error: Package $i is not installed.  Bailing" 1>&2
		exit 2
	fi
done

	
if [ ! -f "$BATIK_DIR/batik-ttf2svg.jar" ]
then
	echo "Error: Batik is not installed or BATIK_DIR is not set. " 1>&2
	echo "Bailing." 1>&2

	exit 3
fi

if [ -d old ]
then
	mkdir old
fi

for i in $*
do
	#.. check to see if it's a TrueType font
	file "$i" | grep "TrueType" > /dev/null
	IS_TTF="$?"

	file "$i" | grep "OpenType" > /dev/null
	IS_OTF="$?"

	if [ "$IS_OTF" = "0" ]
	then
		ORIG_TYPE="otf"
	elif [ "$IS_TTF" = "0" ]
	then
		ORIG_TYPE="ttf"
	fi

	if [ "$IS_OTF" = 0 -o "$IS_TTF" = 0 ]
	then
		cp $i old
	
		NEW_FILE=`echo $i | sed "s/ /_/g"`

		if [ "$i" != "$NEW_FILE" ]
		then
			echo "Removing spaces in font name."
			mv $i $NEW_FILE
			i="$NEW_FILE"
		fi
	
		FILE_STUB=`echo $NEW_FILE | 
			sed "s/\.[tT][tT][fF]$//" |
                        sed "s/\.[oO][tT][fF]$//"`

		# echo $FILE_STUB

		#.. If this is an OTF Font, then convert it to TTF.  

		if [ "$IS_OTF" = "0" -a ! -f $FILE_STUB.ttf ]
		then 
			toTTF $NEW_FILE
			NEW_FILE="$FILE_STUB.ttf"
		fi

		if [ ! -f $FILE_STUB.eot ]
		then
			echo "Converting $FILE_STUB to eot"
			toEOT $NEW_FILE 
		else 
			echo "$FILE_STUB.eot exists, skipping ..."
		fi
	
		if [ ! -f $FILE_STUB.svg ]
                then
			echo "Converting $FILE_STUB to svg"
			toSVG $NEW_FILE $FILE_STUB
		else 
			echo "$FILE_STUB.svg exists, skipping ..."
		fi
	
		if [ ! -f $FILE_STUB.woff ]
                then
			echo "Converting $FILE_STUB to woff"
			toWOFF $NEW_FILE
		else 
			echo "$FILE_STUB.woff exists, skipping ..."
		fi
			 
	
		FILE_STUBS="$FILE_STUBS $FILE_STUB"
	else 
		echo "File $i is not a TrueType or OpenType font. Skipping"
	fi
done


echo "Writing Stylesheet ..."
IFS=$(echo -en " ")
for i in $FILE_STUBS
do
	if [ "$IS_OTF" = "0" ]
	then
		EXTRA_FONT_INFO=" url('$i.otf')  format('opentype'),
	    "
	else 
		EXTRA_FONT_INFO=""
	fi

	echo "Extracting SVG ID"
	SVG_ID=`getSVGID $i.svg`
	
	echo "Getting Font Name"
	FONTNAME=`getFontName $i.$ORIG_TYPE`

	echo "
@font-face {
	font-family: '$FONTNAME';
	src: url('$i.eot?') format('eot'), 
	    $EXTRA_FONT_INFO url('$i.woff') format('woff'), 
	     url('$i.ttf')  format('truetype'),
	     url('$i.svg#$SVG_ID') format('svg');
}" >> stylesheet.css
done
echo "DONE!"
