#!/usr/bin/env bash
# Refs:
# https://github.com/jorisw/ibooks2evernote
# https://stackoverflow.com/questions/7216358/date-command-on-os-x-doesnt-have-iso-8601-i-option
# https://unix.stackexchange.com/questions/107750/how-to-parse-iso8601-dates-with-linux-date-command
# https://www.techonthenet.com/sqlite/functions/datetime.php
# https://askubuntu.com/questions/408775/add-seconds-to-a-given-date-in-bash

#exit on error
set -e
set -u
set -o pipefail

# bins
SQLITE3=/usr/bin/sqlite3
CSV_FILE=$HOME/Downloads/output.csv
GDATE=/usr/local/bin/gdate
GDATE_FORMAT='+%m/%d/%Y %H:%M:%S %p'

# dirs
DOCS=~/Library/Containers/com.apple.iBooksX/Data/Documents
BOOKS_DATABASE_DIRECTORY="$DOCS"/BKLibrary
NOTES_DATABASE_DIRECTORY="$DOCS"/AEAnnotation

# queries
get_ID() {
	local book_title="$1"
	local books_database_file=`find "$BOOKS_DATABASE_DIRECTORY" -iname "*.sqlite"`
	local books_query="SELECT ZASSETID, ZTITLE AS Title, ZAUTHOR AS Author FROM ZBKLIBRARYASSET WHERE ZTITLE IS NOT NULL"
	"SQLITE3" "$books_database_file" "$books_query" | while read line; do
		if [[ $line =~ "$book_title" ]]; then
			get_ID_result=`echo $line | cut -f 1 -d '|'`
			echo $get_ID_result
			# TITLE=`echo $line | cut -f 2 -d '|'`
			# AUTHOR=`echo $line | cut -f 3 -d '|'`
		fi
	done
}

rm_csv_file() {
	rm -vfr "$CSV_FILE"
}

get_notes_query() {
	local notes_query="SELECT ZANNOTATIONREPRESENTATIVETEXT as BroaderText, ZANNOTATIONSELECTEDTEXT as SelectedText, ZANNOTATIONNOTE as Note, ZFUTUREPROOFING5 as Chapter, ZANNOTATIONCREATIONDATE as Created, ZANNOTATIONMODIFICATIONDATE as Modified FROM ZAEANNOTATION WHERE ZANNOTATIONSELECTEDTEXT IS NOT NULL AND ZANNOTATIONASSETID = '"$zassetid"' ORDER BY ZANNOTATIONASSETID ASC,Created ASC"
	echo "$notes_query"
}

get_notes_info() {
	# notes
	local zassetid="$1"
	local notes_query="$2"
	# local notes_database_file=`find "$NOTES_DATABASE_DIRECTORY" -iname "*.sqlite"`
	# The iBooks DB stores the ZANNOTATIONCREATIONDATE and ZANNOTATIONMODIFICATIONDATE values in ISO-8601 standard as seconds from the date of 2000-01-01 00:00:00 +0000.
	# For example,
	# if I had a value of 588916720.882715 in the ZANNOTATIONCREATIONDATE field I could do the following to get the actual date that
	# this value represents in human readable form:
	# /usr/local/bin/gdate '+%m/%d/%Y %I:%M %p' --date="2000-01-01 00:00:00 +0000 + 588916720.882715 seconds"
	# ; is the delimiter
	"SQLITE3" "$notes_database_file" "$notes_query" | while read line; do

		# broaderText
		broaderText=`echo $line | cut -f 1 -d '|'`
		if [ -z ${broaderText+x} ]; then
			# echo "broaderText is unset";
			broaderText="''"
		else
			# echo "broaderText is set to '$broaderText'";
			broaderText=`echo $line | cut -f 1 -d '|'`
		fi

		# selectedText
		selectedText=`echo $line | cut -f 2 -d '|'`
		if [ -z ${selectedText+x} ]; then
			# echo "selectedText is unset";
			selectedText="''"
		else
			# echo "selectedText is set to '$selectedText'";
			selectedText=`echo $line | cut -f 2 -d '|'`
		fi

		# note
		note=`echo $line | cut -f 3 -d '|'`
		if [ -z ${note+x} ]; then
			# echo "note is unset";
			note="''"
		else
			# echo "note is set to '$note'";
			note=`echo $line | cut -f 3 -d '|'`
		fi

		## DATES
		chapterLine=`echo $line | cut -f 4 -d '|'`
		chapter=`echo $line | cut -f 4 -d '|' | xargs -I {} sh -c "$GDATE '$GDATE_FORMAT' --date='2000-01-01 00:00:00 + 0000 + {} seconds'"`
		if [ -z ${chapter+x} ]; then
			# echo "chapter is unset";
			chapter="''"
		else
			chapter=`echo $line | cut -f 4 -d '|' | xargs -I {} sh -c "$GDATE '$GDATE_FORMAT' --date='2000-01-01 00:00:00 +0000 + {} seconds'"`
		fi

		created=`echo $line | cut -f 5 -d '|' | xargs -I {} sh -c "$GDATE '$GDATE_FORMAT' --date='2000-01-01 00:00:00 + 0000 + {} seconds'"`
		if [ -z ${created+x} ]; then
			# echo "created is unset";
			created="''"
		else
			# echo "created is set to '$created'";
			created=`echo $line | cut -f 5 -d '|' | xargs -I {} sh -c "$GDATE '$GDATE_FORMAT' --date='2000-01-01 00:00:00 + 0000 + {} seconds'"`
		fi

		modified=`echo $line | cut -f 6 -d '|' | xargs -I {} sh -c "$GDATE '$GDATE_FORMAT' --date='2000-01-01 00:00:00 + 0000 + {} seconds'"`
		if [ -z ${modified+x} ]; then
			# echo "modified is unset";
			modified="''"
		else
			modified=`echo $line | cut -f 6 -d '|' | xargs -I {} sh -c "$GDATE '$GDATE_FORMAT' --date='2000-01-01 00:00:00 + 0000 + {} seconds'"`
		fi
		echo "$selectedText|Chapter: $chapter|Created: $created|Modified: $modified;back"
		# echo "$selectedText|Chapter: $chapter|Created: $created|Modified: $modified;back" >> "$CSV_FILE"
	done

	echo "Done! Output file is @ $CSV_FILE"
}

main() {
	id="$(get_ID "$1")"
	rm_csv_file
	notes_query=$(get_notes_query)
	get_notes_info "$id" "$notes_query"
}

main "$1"
