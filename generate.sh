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
  echo $(identify -precision 9 -format "%[fx:(w*h)/1000000]" $1 | xargs printf "%0.1f\n")
}

function hasGpsInfo {
  echo $(exiv2 -pa pr $1 | grep Exif.GPSInfo.GPSLatitude > /dev/null && echo yes || echo no)
}

function fixWhitespace {
  echo $(cat - | tr -d '\n' | sed 's/\s\{2,\}/ /g')
}

function writeDownloadHtmlStart {
  outFileName=$1
  cat <<EOF > $outFileName
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <style>
    body {
      display: flex;
      flex-direction: column;
    }

    button {
      margin-bottom: 1em;
      font-size: 3em;
    }
  </style>
</head>
<body>
EOF
}

function writeDownloadHtmlEnd {
  outFileName=$1
  cat <<EOF >> $outFileName
  <script charset="utf-8">
    async function doDownload(filename) {
      try {
        const resp = await fetch(filename)
        const blob = await resp.blob()
        triggerDownload(blob, filename)
      } catch (err) {
        alert('We failed: ' + err)
      }
    }

    function triggerDownload(blob, filename) {
      if (window.navigator && window.navigator.msSaveOrOpenBlob) {
        window.navigator.msSaveOrOpenBlob(blob, filename)
        return
      }
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      document.body.appendChild(a)
      a.href = url
      a.download = filename
      a.click()
      window.URL.revokeObjectURL(url)
      document.body.removeChild(a)
    }
  </script>
</body>
</html>
EOF
}

for curr in $(ls $inputDir); do
  echo "[INFO] processing $curr"
  baseFileName=`bash -c "echo $curr | sed 's/.jpg//'"`
  htmlFileName=$outputDir/$baseFileName.html
  writeDownloadHtmlStart $htmlFileName

  echo -e "### $baseFileName\n" >> $theReadme
  echo -e "![]($outputDir/${baseFileName}-${smallestScale}px.jpg)\n" >> $theReadme
  echo -e "[Force download page]($htmlFileName)\n" >> $theReadme

  echo -e "| Size | Link | File size | Dimensions | Megapixels | Has GPS |" >> $theReadme
  echo -e "|--|--|--|--|--|--|" >> $theReadme
  originalFile=$inputDir/$curr
  echo -e "| original | [link]($originalFile) | $(getFilesize $originalFile) |
    $(getDimensions $originalFile) | $(getMegapixels $originalFile)mp |
    $(hasGpsInfo $originalFile) |" | fixWhitespace >> $theReadme
  for currScale in 3000 2000 1000 $smallestScale; do
    scaledFile=${baseFileName}-${currScale}px.jpg
    scaledFilePath=$outputDir/$scaledFile
    convert -scale $currScale $inputDir/$curr $scaledFilePath
    echo -e "| ${currScale}px | [link]($scaledFilePath) | $(getFilesize $scaledFilePath)
    | $(getDimensions $scaledFilePath) | $(getMegapixels $scaledFilePath)mp |
      $(hasGpsInfo $scaledFilePath) |" | fixWhitespace >> $theReadme

    echo "<button onclick=\"doDownload('$scaledFile')\">Download $scaledFile</button>" >> $htmlFileName
  done
  writeDownloadHtmlEnd $htmlFileName
  echo -e "\n\n" >> $theReadme
done
