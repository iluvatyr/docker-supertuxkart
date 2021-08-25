#!/usr/bin/env bash

STK_DIR=/srv/Config/STK #(change to parent folder of addons)

TMP_DIR="$STK_DIR"/tmp
ADDONS_DIR="$STK_DIR"/addons

mkdir -p "$TMP_DIR"

echo "Downloading addon index..."
curl -fLs https://online.supertuxkart.net/downloads/xml/assets.xml > "$TMP_DIR"/assets.xml

#Removing Karts from assets.xml
grep -v "<kart id=" "$TMP_DIR"/assets.xml >"$TMP_DIR"/tmp.xml
mv "$TMP_DIR"/tmp.xml "$TMP_DIR"/assets.xml

TRACK_REGEX='^\s*<track'
ARENA_REGEX='^\s*<arena'
KART_REGEX='^\s*<kart'
ID_REGEX='id="([^"]+)"'
FILE_REGEX='file="([^"]+)"'
NAME_REGEX='name="([^"]+)"'
DESIGNER_REGEX='designer="([^"]+)"'
REVISION_REGEX='revision="([^"]+)"'


counter=0 # Counter just to see if something happens.
while IFS='<' read -r line; do
  counter=$((counter+1))
  if (( $counter % 10 == 0 )); then
    echo "$counter/$lines"
  fi
  if [[ $line =~ $TRACK_REGEX ]]; then
    addon_subdir="tracks"
    type_name="Track"
  elif [[ $line =~ $ARENA_REGEX ]]; then
    addon_subdir="tracks"
    type_name="Arena"
  elif [[ $line =~ $KART_REGEX ]]; then
    addon_subdir="karts"
    type_name="Kart"
  else
    continue
  fi

  [[ $line =~ $ID_REGEX ]]
  id="${BASH_REMATCH[1]}"
  revision=0

  target_dir="$ADDONS_DIR/$addon_subdir/$id"
  
  #Getting currently installed revision
  if [[ -d "$target_dir" ]]; then
    trackxml=`cat "$target_dir/track.xml"`
    [[ $trackxml =~ $REVISION_REGEX ]]
    installed_revision="${BASH_REMATCH[1]}"

    # Find highest revision available from supertuxkart...
    while IFS='<' read -r line; do
      [[ $line =~ $ID_REGEX ]]
      found_id="${BASH_REMATCH[1]}"
      [[ $line =~ $FILE_REGEX ]]
      found_file="${BASH_REMATCH[1]}"
      [[ $line =~ $NAME_REGEX ]]
      found_name="${BASH_REMATCH[1]}"
      [[ $line =~ $DESIGNER_REGEX ]]
      found_designer="${BASH_REMATCH[1]}"
      [[ $line =~ $REVISION_REGEX ]]
      found_revision="${BASH_REMATCH[1]}"

      if [[ "$id" == "$found_id" ]] && [[ "$found_revision" -ge "$revision" ]]; then
        revision="$found_revision"
        file="$found_file"
        name="$found_name"
        designer="$found_designer"
      fi
    done < "$TMP_DIR"/assets.xml #find highest revision of track with $id
  
    #Comparing installed revision with available revision and downloading if new available
    if [[ $revision > $installed_revision ]]; then
    echo "Newer revision available for $type_name: '$name' by $designer"
    echo -n "updating from revision $installed_revision to revision $revision ..."
        curl -fLs "$file" > "$TMP_DIR"/track.zip
        echo -en " done\n- extracting..."
        unzip -qo "$TMP_DIR"/track.zip -d "$target_dir"
        echo " done"
    fi
  fi
done < "$TMP_DIR"/assets.xml #Iterating through tracks of downloaded assets.xml

echo "All tracks up to date"
