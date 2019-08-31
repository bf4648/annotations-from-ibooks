#!/usr/bin/env bash
# Refs:
# https://github.com/jorisw/ibooks2evernote
# https://stackoverflow.com/questions/7216358/date-command-on-os-x-doesnt-have-iso-8601-i-option
# https://unix.stackexchange.com/questions/107750/how-to-parse-iso8601-dates-with-linux-date-command
# https://www.techonthenet.com/sqlite/functions/datetime.php
# https://askubuntu.com/questions/408775/add-seconds-to-a-given-date-in-bash
set -euo pipefail

BOOK_TITLE="The Books Title"

# bins
SQLITE3=/usr/bin/sqlite3
CSV_FILE=$HOME/Downloads/output.csv
GDATE=/usr/local/bin/gdate
GDATE_FORMAT='+%m/%d/%Y %H:%M:%S %p'

# dirs
DOCS=~/Library/Containers/com.apple.iBooksX/Data/Documents
BOOKS_DATABASE_DIRECTORY="$DOCS"/BKLibrary
NOTES_DATABASE_DIRECTORY="$DOCS"/AEAnnotation

# files
BOOKS_DATABASE_FILE=`find "$BOOKS_DATABASE_DIRECTORY" -iname "*.sqlite"`
NOTES_DATABASE_FILE=`find "$NOTES_DATABASE_DIRECTORY" -iname "*.sqlite"`

# queries
BOOKS_QUERY="SELECT ZASSETID, ZTITLE AS Title, ZAUTHOR AS Author FROM ZBKLIBRARYASSET WHERE ZTITLE IS NOT NULL"
while read -r line; do
	# =~ is a regex expression
	if [[ $line =~ "$BOOK_TITLE" ]]; then
		# echo "$line"
		ZASSETID=`echo $line | cut -f 1 -d '|'`
		Title=`echo $line | cut -f 2 -d '|'`
		Author=`echo $line | cut -f 3 -d '|'`
	fi
done < <("$SQLITE3" "$BOOKS_DATABASE_FILE" "$BOOKS_QUERY")

# notes
NOTES_QUERY="SELECT ZANNOTATIONREPRESENTATIVETEXT as BroaderText, ZANNOTATIONSELECTEDTEXT as SelectedText, ZANNOTATIONNOTE as Note, ZFUTUREPROOFING5 as Chapter, ZANNOTATIONCREATIONDATE as Created, ZANNOTATIONMODIFICATIONDATE as Modified FROM ZAEANNOTATION WHERE ZANNOTATIONSELECTEDTEXT IS NOT NULL AND ZANNOTATIONASSETID = '"$ZASSETID"' ORDER BY ZANNOTATIONASSETID ASC,Created ASC"

# From the terminal:
# Example: gdate '+%m/%d/%Y %I:%M %p' --date="2000-01-01 00:00:00 +0000 + 588916720.882715 seconds"
# where the 588916720.882715 seconds is stored as time stamp since 2000-01-01 00:00:00 +0000 + 588916720.882715 seconds in the iBooks DB
# ; is the delimited
rm -rfv "$CSV_FILE"
while read -r line; do
	# =~ is a regex expression
	BroaderText=`echo $line | cut -f 1 -d '|'`
	SelectedText=`echo $line | cut -f 2 -d '|'`
	Note=`echo $line | cut -f 3 -d '|'`
	Chapter=`echo $line | cut -f 4 -d '|' | xargs -I {} sh -c "$GDATE '$GDATE_FORMAT' --date='2000-01-01 00:00:00 +0000 + {} seconds'"`
	Created=`echo $line | cut -f 5 -d '|' | xargs -I {} sh -c "$GDATE '$GDATE_FORMAT' --date='2000-01-01 00:00:00 +0000 + {} seconds'"`
	Modified=`echo $line | cut -f 6 -d '|' | xargs -I {} sh -c "$GDATE '$GDATE_FORMAT' --date='2000-01-01 00:00:00 +0000 + {} seconds'"`
	echo "$SelectedText|Chapter: $Chapter|Created: $Created|Modified: $Modified;back" >> "$CSV_FILE"
done < <("$SQLITE3" "$NOTES_DATABASE_FILE" "$NOTES_QUERY")

echo "Done! Output file is @ $CSV_FILE"
