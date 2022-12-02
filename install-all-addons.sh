#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ADDONS_DIR="$HOME/.local/share/supertuxkart/addons/"
TMP_DIR="/tmp/addon_install"

mkdir -p "$TMP_DIR"

echo "Downloading addon index..."
curl -fLsS https://online.supertuxkart.net/downloads/xml/assets.xml > "$TMP_DIR"/assets.xml

#Removing Karts from assets.xml, comment out below 2 lines to also download karts
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

while IFS='<' read -r line; do
  echo -n "." #just to see that something is happening
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

  if [[ ! -d "$target_dir" ]]; then
    # Find highest revision...
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
    done < "$TMP_DIR"/assets.xml
    echo ""
    echo "$type_name: '$name' by $designer (revision $revision)"
    echo -n '- downloading...'
    curl -fLs "$file" > "$TMP_DIR"/track.zip
    echo -en " done\n- extracting..."
    mkdir -p "$target_dir"
    unzip -qo "$TMP_DIR"/track.zip -d "$target_dir"
    echo " done"
  fi
done < "$TMP_DIR"/assets.xml
rm -r "$TMP_DIR"
echo "Installation done."
