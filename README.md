# Getting started

This little script just dumps the ibooks annotations using the title of the book into a semicolon delimated file in ~/Downloads/output.csv.  You can then import this file into Anki since Anki will import csv files.

## Install the Dependencies

If you are on a mac you will need to install sqlite3 and gdate (which is included in the coreutils package)

```shell
brew install coreutils sqlite3 rename
```

## Get the Title of the Book

Open using sqlitedb browser

```
open -a /Applications/DB\ Browser\ for\ SQLite.app ~/Library/Containers/com.apple.iBooksX/Data/Documents/BKLibrary/path/to/sqlite/db
```

Enter in the following sql query into the 'Execute SQL' tab

```sql
SELECT ZASSETID, ZTITLE AS Title, ZAUTHOR AS Author FROM ZBKLIBRARYASSET WHERE ZTITLE IS NOT NULL
```

## Pass the script the book title

```shell
./dump-annotations.sh "Book Title"
```
