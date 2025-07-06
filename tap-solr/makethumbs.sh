ORIGINALfile="$1"

while read -r ORIGINAL
do
  ((COUNTER++))
  # extract and set filenames and directory paths for input and output
  F=$(basename "${ORIGINAL}")
  F2=${F/.*/}
  F2=${F2// /_}
  D=$(dirname "${ORIGINAL}")
  echo "${COUNTER} ${F}"
  magick "${ORIGINAL}" -quality 50 -gravity center -crop 1024x1024+0+0 +repage square_1024/"${F2}.thumb.jpeg"
done <  ${ORIGINALfile}
