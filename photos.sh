#!/bin/bash
# photos.sh — builds the Photos page from folders.
#
#   photos-inbox/
#     Ecuador/            one folder = one album (folder name = album title)
#       01.jpg            order = file name order; first file = cover
#       02_volcano.jpg
#       keywords.txt      OPTIONAL: extra search words, e.g. "andes volcano"
#       date.txt          OPTIONAL: YYYY-MM-DD, to control album order
#     feed/               loose photos for the main feed
#       01_halloween-forest.jpg   (words in the name = caption + search tags)
#
# Usage:  ./photos.sh      (run from the brume folder)

set -e
cd "$(dirname "$0")"

INBOX="photos-inbox"
OUT="assets/images/photos"
SIZE=1600
QUALITY=75

if [ ! -d "$INBOX" ]; then
  echo "No $INBOX folder found. Create it and add folders (one per album, plus 'feed')."
  exit 1
fi

resize() { # $1 source  $2 destination
  if command -v sips >/dev/null 2>&1; then
    sips -Z $SIZE -s format jpeg -s formatOptions $QUALITY "$1" --out "$2" >/dev/null
  else
    convert "$1" -auto-orient -resize ${SIZE}x${SIZE}\> -quality $QUALITY "$2"
  fi
}

slug() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'; }
fname() { # file name -> safe lowercase .jpg name
  local b="${1%.*}"
  echo "$(echo "$b" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g').jpg"
}
words() { # "03_halloween-forest" -> "halloween forest"
  local b="${1%.*}"
  echo "$b" | sed -E 's/^[0-9]+//; s/[_-]+/ /g; s/^ +| +$//g' | tr '[:upper:]' '[:lower:]'
}
yq() { echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

list_images() { # sorted image files in dir $1
  find "$1" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.heic' \) \
    ! -name '.*' | sort
}

mkdir -p _albums _data "$OUT"
rm -f _albums/*.md 2>/dev/null || true
: > _data/photos.yml
keep="$(mktemp)"

# ---- albums
for dir in "$INBOX"/*/; do
  name="$(basename "$dir")"
  [ "$name" = "feed" ] && continue
  s="$(slug "$name")"; [ -z "$s" ] && continue
  mkdir -p "$OUT/$s"
  paths=""; first=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    out="$OUT/$s/$(fname "$(basename "$f")")"
    echo "$out" >> "$keep"
    if [ ! -f "$out" ] || [ "$f" -nt "$out" ]; then resize "$f" "$out"; echo "  resized $out"; fi
    [ -z "$first" ] && first="/$out"
    paths="$paths  - /$out"$'\n'
  done < <(list_images "$dir")
  [ -z "$first" ] && continue

  kw="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
  [ -f "$dir/keywords.txt" ] && kw="$kw $(tr '\n' ' ' < "$dir/keywords.txt" | tr '[:upper:]' '[:lower:]')"
  if [ -f "$dir/date.txt" ]; then d="$(tr -d '[:space:]' < "$dir/date.txt")"
  else newest="$(ls -t "$dir" | head -1)"; d="$(date -r "$dir/$newest" +%Y-%m-%d)"; fi

  {
    echo "---"
    echo "layout: album"
    echo "title: \"$(yq "$name")\""
    echo "date: $d"
    echo "cover: $first"
    echo "keywords: \"$(yq "$kw")\""
    echo "photos:"
    printf "%s" "$paths"
    echo "---"
  } > "_albums/$s.md"
  echo "album: $name ($(echo -n "$paths" | grep -c .) photos)"
done

# ---- feed
if [ -d "$INBOX/feed" ]; then
  mkdir -p "$OUT/feed"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    base="$(basename "$f")"
    out="$OUT/feed/$(fname "$base")"
    echo "$out" >> "$keep"
    if [ ! -f "$out" ] || [ "$f" -nt "$out" ]; then resize "$f" "$out"; echo "  resized $out"; fi
    w="$(words "$base")"
    {
      echo "- image: /$out"
      echo "  caption: \"$(yq "$w")\""
      echo "  tags: \"$(yq "$w")\""
    } >> _data/photos.yml
  done < <(list_images "$INBOX/feed" | sort -t/ -k3,3nr)
  echo "feed: $(grep -c '^- image' _data/photos.yml) photos"
fi

# ---- remove outputs whose source is gone
find "$OUT" -type f ! -name '.*' | while IFS= read -r f; do
  grep -qxF "$f" "$keep" || { rm -f "$f" 2>/dev/null; echo "  removed $f"; }
done
rm -f "$keep" 2>/dev/null || true
echo "Done. Preview: bundle exec jekyll serve"
