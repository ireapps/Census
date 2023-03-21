#!/usr/bin/env bash
# usage: ./load_sqlite.sh [TABLE CODE] [STATE FIPS CODE] [SUMMARY LEVEL] [DATABASE]
# supports all 331 Census 2010 tables
# only the five summary levels supported by the IRE Census app:
#   040 State
#   050 County
#   060 County Subdivision
#   140 Census Tract
#   160 Place
# see also http://census.ire.org/data/bulkdata.html
# list of FIPS state codes at http://en.wikipedia.org/wiki/Federal_Information_Processing_Standard_state_code#FIPS_state_codes

TABLE=$1
STATE=$2
SUMLEV=$3
DATABASE=$4
if [[ X"" = X"$DATABASE" ]]; then 
        DATABASE='nicar.db' 
fi
LOWER_TABLE=`echo $TABLE | tr '[A-Z]' '[a-z]'`
CSV_FILENAME=all_${SUMLEV}_in_${STATE}.${TABLE}.csv

if command -v gzcat >/dev/null; then
        GZCAT_CMD=gzcat
elif command -v zcat >/dev/null; then
        GZCAT_CMD=zcat
else        
        echo "gzcat or zcat not found"
        exit 1
fi

if command -v spatialite >/dev/null; then
        SQLITE_CMD=spatialite
elif command -v spatialite >/dev/null; then
        SQLITE_CMD=sqlite3
else
        echo "spatialite or sqlite3 command not found"
        exit 1
fi

echo "Loading table $TABLE for state $STATE and summary level $SUMLEV into $DATABASE"
curl https://raw.github.com/ireapps/census/master/tools/sql/ire_export/ire_${TABLE}.sql | sqlite3 $DATABASE
# Use tail to strip the header row from the file so it doesn't get imported
curl http://censusdata.ire.org/${STATE}/all_${SUMLEV}_in_${STATE}.${TABLE}.csv | $GZCAT_CMD | tail -n +2 > ${CSV_FILENAME} 
echo -e ".mode csv\n.import ${CSV_FILENAME} ire_${LOWER_TABLE}\n" | ${SQLITE_CMD} ${DATABASE}
