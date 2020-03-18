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

for curr in $(ls $inputDir); do
  echo "[INFO] processing $curr"
  baseFileName=`bash -c "echo $curr | sed 's/.jpg//'"`
  echo -e "### $baseFileName\n" >> $theReadme
  echo -e "![]($outputDir/${baseFileName}-${smallestScale}px.jpg)\n" >> $theReadme
  echo -e "| Size | Link |" >> $theReadme
  echo -e "|--|--|" >> $theReadme
  originalFile=$outputDir/${baseFileName}-original.jpg
  ln -s ../$inputDir/$curr $originalFile
  echo -e "| original | [link]($originalFile) |" >> $theReadme
  for currScale in 1000 $smallestScale; do
    scaledFile=$outputDir/${baseFileName}-${currScale}px.jpg
    convert -scale $currScale $inputDir/$curr $scaledFile
    echo -e "| $currScale | [link]($scaledFile)|" >> $theReadme
  done
  echo -e "\n\n" >> $theReadme
done
