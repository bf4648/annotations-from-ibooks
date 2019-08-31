# Getting started

This is my little shell script that I wrote to dump the annotations from iBooks.  The only thing that needs to be changed in the script is the BOOK_TITLE variable near the top of the script.  

```shell
BOOK_TITLE="The Books Title" # change this to your target book title
```

This little script just dumps the ibooks annotations using the title of the book into a semicolon delimated file in ~/Downloads/output.csv.  You can then import this file into Anki since Anki will import csv files.

# Dependencies 

If you are on a mac you will need to install sqlite3 and gdate (which is included in the coreutils package)

```shell
brew install coreutils sqlite3
```
