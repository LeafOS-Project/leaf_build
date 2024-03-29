#!/bin/bash

BASEDIR="$1"
BASEURL="$2"

if [ -z "$BASEDIR" ] || [ -z "$BASEURL" ]; then
	echo "Usage: $0 <basedir> <baseurl>"
	exit 1
fi

function get_metadata_value() {
	local METADATA_LOCAL="$1"
	local KEY="$2"
	echo "$METADATA_LOCAL" | grep "$KEY=" | cut -f2- -d '='
}

find "$BASEDIR" -name *.zip -or -name *.sha256 -mtime +50 -delete -print
find "$BASEDIR" -empty -type d -delete -print

echo "DELETE FROM leaf_ota;" > transaction.sql
for OTA in $(find "$BASEDIR" -name *.zip); do
	echo "$OTA"
	[ ! -f "$OTA".sha256 ] && sha256sum "$OTA" > "$OTA".sha256

	METADATA=$(unzip -p - "$OTA" META-INF/com/android/metadata 2>/dev/null)
	[ -z "$METADATA" ] && echo "empty"
	[ -z "$METADATA" ] && continue # Skip GSI
	DEVICE=$(get_metadata_value "$METADATA" "pre-device")
	DATETIME=$(get_metadata_value "$METADATA" "post-timestamp")
	FILENAME=$(basename "$OTA")
	ID=$(cat "$OTA".sha256 | cut -f1 -d ' ')
	ROMTYPE="OFFICIAL"
	SIZE=$(du -b "$OTA" | cut -f1)
	URL=$(echo "$OTA" | sed "s|$BASEDIR|$BASEURL|g")
	VERSION=$(echo "$OTA" | cut -f2 -d '-')
	FLAVOR=$(echo "$OTA" | rev | cut -f2 -d '-' | rev)
	INCREMENTAL=$(get_metadata_value "$METADATA" "post-build-incremental")
	INCREMENTAL_BASE=$(get_metadata_value "$METADATA" "pre-build-incremental")

	echo "INSERT INTO leaf_ota(device, datetime, filename, id, romtype, size, url, version, " \
		"flavor, incremental, incremental_base) VALUES (\"$DEVICE\", \"$DATETIME\", " \
		"\"$FILENAME\", \"$ID\", \"$ROMTYPE\", \"$SIZE\", \"$URL\", \"$VERSION\", " \
		"\"$FLAVOR\", \"$INCREMENTAL\", \"$INCREMENTAL_BASE\");" >> transaction.sql
done

echo "UPDATE leaf_ota SET incremental_base = NULL WHERE incremental_base = '';" >> transaction.sql
cat transaction.sql | mariadb -u leaf -pleaf -D "leaf_ota"
rm transaction.sql
