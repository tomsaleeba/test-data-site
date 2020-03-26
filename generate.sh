#!/bin/bash
# generates the "github pages site" from the original images we have in an
# idempotent fashion. Just run this, commit and the site is updated.
set -euo pipefail
if [ "${DEBUG:-0}" = 1 ]; then
  # run with DEBUG=1 env var to enable
  set -x
fi
cd `dirname "$0"`

inputDir=./originals
outputDir=./generated
theReadme=./README.md
smallestScale=100

cat <<EOF > $theReadme
A repo for some test assets that I need when testing web apps.
Things like photos or various sizes, including ones with EXIF data.

## Photos

EOF

rm -f $outputDir/*
mkdir -p $outputDir

function getFilesize {
  echo $(bash -c "stat -c '%s' $1 | numfmt --to=si")
}

function getDimensions {
  # the percent escapes comes from https://imagemagick.org/script/escape.php
  echo $(identify -format "%wx%h" $1)
}

function getMegapixels {
  # the fx: is from ImageMagick https://imagemagick.org/script/fx.php
  echo $(identify -format "%[fx:round((w*h)/1000000)]" $1)
}

function hasGpsInfo {
  echo $(exiv2 -pa pr $1 | grep Exif.GPSInfo.GPSLatitude > /dev/null && echo yes || echo no)
}

function fixWhitespace {
  echo $(cat - | tr -d '\n' | sed 's/\s\{2,\}/ /g')
}

for curr in $(ls $inputDir); do
  echo "[INFO] processing $curr"
  baseFileName=`bash -c "echo $curr | sed 's/.jpg//'"`
  echo -e "### $baseFileName\n" >> $theReadme
  echo -e "![]($outputDir/${baseFileName}-${smallestScale}px.jpg)\n" >> $theReadme
  echo -e "| Size | Link | File size | Dimensions | Megapixels | Has GPS |" >> $theReadme
  echo -e "|--|--|--|--|--|--|" >> $theReadme
  originalFile=$inputDir/$curr
  echo -e "| original | [link]($originalFile) | $(getFilesize $originalFile) |
    $(getDimensions $originalFile) | $(getMegapixels $originalFile)mp |
    $(hasGpsInfo $originalFile) |" | fixWhitespace >> $theReadme
  for currScale in 3000 2000 1000 $smallestScale; do
    scaledFile=$outputDir/${baseFileName}-${currScale}px.jpg
    convert -scale $currScale $inputDir/$curr $scaledFile
    echo -e "| ${currScale}px | [link]($scaledFile) | $(getFilesize $scaledFile)
    | $(getDimensions $scaledFile) | $(getMegapixels $scaledFile)mp |
      $(hasGpsInfo $scaledFile) |" | fixWhitespace >> $theReadme
  done
  echo -e "\n\n" >> $theReadme
done
