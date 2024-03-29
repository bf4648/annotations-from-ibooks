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
			id_result=`echo $line | cut -f 1 -d '|'`
			echo "$id_result"
			# TITLE=`echo $line | cut -f 2 -d '|'`
			# AUTHOR=`echo $line | cut -f 3 -d '|'`
		fi
	done
}

rm_csv_file() {
	rm -rfv "$CSV_FILE"
}

get_notes_query() {
	local zassetid="$1"
	local notes_query="SELECT ZANNOTATIONREPRESENTATIVETEXT as BroaderText, ZANNOTATIONSELECTEDTEXT as SelectedText, ZANNOTATIONNOTE as Note, ZFUTUREPROOFING5 as Chapter, ZANNOTATIONCREATIONDATE as Created, ZANNOTATIONMODIFICATIONDATE as Modified FROM ZAEANNOTATION WHERE ZANNOTATIONSELECTEDTEXT IS NOT NULL AND ZANNOTATIONASSETID = '"$zassetid"' ORDER BY ZANNOTATIONASSETID ASC,Created ASC"
	echo "$notes_query"
}

get_notes_db_file() {
	local notes_database_file=`find "$NOTES_DATABASE_DIRECTORY" -iname "*.sqlite"`
	echo "$notes_database_file"
}

get_text_by_delimiter() {
	local line="$1"
	local delimiter="$2"
	text=`echo $line | cut -f "$delimiter" -d '|'`
	if [ -z ${text+x} ]; then
		# echo "text is unset";
		text="''"
	else
		if [[ "$delimiter" -gt 4 ]]; then
			# echo "$delimiter is greater than 4"
			# The iBooks DB stores the ZANNOTATIONCREATIONDATE and ZANNOTATIONMODIFICATIONDATE values in ISO-8601 standard
			# as seconds from the date of 2000-01-01 00:00:00 +0000.
			# For example,
			# if I had a value of 588916720.882715 in the ZANNOTATIONCREATIONDATE field I could do the following to get the actual date that
			# this value represents in human readable form:
			# /usr/local/bin/gdate '+%m/%d/%Y %I:%M %p' --date="2000-01-01 00:00:00 +0000 + 588916720.882715 seconds"
			text=`echo $text | cut -f "$delimiter" -d '|' | xargs -I {} sh -c "$GDATE '$GDATE_FORMAT' --date='2000-01-01 00:00:00 + 0000 + {} seconds'"`
			# echo `date -d "text"`
		else
			# echo "text is set to '$text'"
			text=`echo $line | cut -f "$delimiter" -d '|'`
		fi
	fi
	echo "$text"
}

get_notes_info() {
	local notes_query="$1"
	local notes_database_file="$2"
	local title="$3"
	# \t is the delimiter
	"SQLITE3" "$notes_database_file" "$notes_query" | while read line; do
		# echo "Line: $line"
		local border_text=$(get_text_by_delimiter "$line" 1)
		local selectedText=$(get_text_by_delimiter "$line" 2)
		local note_text=$(get_text_by_delimiter "$line" 3)

		# Dates
		local unsanitized_chapter=$(get_text_by_delimiter "$line" 4)
		local chapter=$(get_sanitize "$unsanitized_chapter")
		local created=$(get_text_by_delimiter "$line" 5)
		local modified=$(get_text_by_delimiter "$line" 6)
		# echo -e "Front: $selectedText\tBack: back\tTag: $chapter\tCreated: $created\tModified: $modified" >> "$CSV_FILE"
		echo -e "$selectedText\tback\t"$title",$chapter" >> "$CSV_FILE"
	done
	echo "Done! Output file is @ $CSV_FILE"
}

get_sanitize() {
	local passedInString="$1"
	local result=`echo $passedInString | tr -s '[:blank:]' '-' | tr '[:upper:]' '[:lower:]'`
	echo "$result"
}

main() {
	title="$1"
	id="$(get_ID "$title")"
	rm_csv_file
	notes_query=$(get_notes_query "$id")
	notes_db_file=$(get_notes_db_file)
	unsanitized_title=`echo $title | cut -f 1 -d ':'`
	sanitized_title=$(get_sanitize "$unsanitized_title")
	get_notes_info "$notes_query" "$notes_db_file" "$sanitized_title"
}

main "$1"
