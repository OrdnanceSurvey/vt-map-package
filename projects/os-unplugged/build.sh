#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

# arg1: download URL
# arg2: output directory
explode () {
    URL=$1
    if [ -z "$URL" ]; then
        warning "Download URL parameter is required!  This is the URL to download an MBTiles file"
        exit 1
    fi
    DIRECTORY=$2
    if [ -z "$DIRECTORY" ]; then
        warning "Output directory required!"
        exit 1
    fi

    OUTPUT_FILE=$(download $URL)
    OUTPUT_UNPACKED=""
    if [ ! -d $DIRECTORY ]; then
        extension=$(extension $OUTPUT_FILE)
        if [ "$extension" == "tar.gz" ]; then
            OUTPUT_UNPACKED=$(unpack_tar_gz $OUTPUT_FILE)
        elif [ "$extension" == "mbtiles" ]; then
            OUTPUT_UNPACKED=$(unpack_mbtiles $OUTPUT_FILE)
        else
            warning "unknown extension: '$extension'.  Terminating!"
            exit 1
        fi
        if [ ! -d $OUTPUT_UNPACKED ]; then
            warning "problem unpacking data!"
            exit 1
        fi
        mv $OUTPUT_UNPACKED $DIRECTORY
    else
        warning "$DIRECTORY exists - not unpacking!"
    fi
}

extension() {
    filename=$1
    if [ -z "$filename" ]; then
        warning "Filename is required!"
        exit 1
    fi
    extension=${filename#*.}
    echo $extension
}

# arg1: download URL
download () {
    URL=$1
    if [ -z "$URL" ]; then
        warning "Download URL parameter is required!  This is the URL to download an MBTiles file"
        exit 1
    fi

    FILENAME="${URL##*/}"

    # Download if file not already there
    if [ ! -f $FILENAME ]; then
        wget $URL > /dev/null 2>&1
    else
        warning "$FILENAME already there...skipping download."
    fi

    if [ -z "$FILENAME" ]; then
        warning "ERROR - cannot get filename for download"
        exit 1
    fi

    echo $FILENAME
}

# arg1: the mbtiles filename to unpack
# echo location of unpacked data
# Dev note: we redirect output because this function must only echo a single response
unpack_mbtiles () {
    FILENAME=$1
    OUTPUT_FILENAME=output_$FILENAME
    if [ ! -d $OUTPUT_FILENAME ]; then
        warning "Unpacking.  This might take a while..."
        mb-util --image_format=pbf $FILENAME $OUTPUT_FILENAME > /dev/null 2>&1

        if [ ! -d $OUTPUT_FILENAME ]; then
            warning "aborting - could not unpack $OUTPUT_FILENAME"
            exit 1
        fi

        warning "adding pbf extension.  This might take a while..."
        find ./$OUTPUT_FILENAME -type f | grep -v json$ | xargs -I{} mv '{}' '{}.pbf' > /dev/null 2>&1
        gzip -d -r -S .pbf ./$OUTPUT_FILENAME/* > /dev/null 2>&1
    else
        warning "'$OUTPUT_FILENAME' appears to be unpacked - ignoring!"
    fi
    echo $OUTPUT_FILENAME
}

# arg1: the mbtiles filename to unpack
# echo location of unpacked data
# Dev note: we redirect output because this function must only echo a single response
unpack_tar_gz () {
    FILENAME=$1
    OUTPUT_FILENAME=output_$FILENAME
    if [ ! -d $OUTPUT_FILENAME ]; then
        warning "Unpacking.  This might take a while..."
        mkdir $OUTPUT_FILENAME
        tar zxvf $FILENAME -C $OUTPUT_FILENAME > /dev/null 2>&1
        #mb-util --image_format=pbf $FILENAME $OUTPUT_FILENAME > /dev/null 2>&1

        if [ ! -d $OUTPUT_FILENAME ]; then
            warning "aborting - could not unpack $OUTPUT_FILENAME"
            exit 1
        fi

        # warning "adding pbf extension.  This might take a while..."
        # find ./$OUTPUT_FILENAME -type f | grep -v json$ | xargs -I{} mv '{}' '{}.pbf' > /dev/null 2>&1
        # gzip -d -r -S .pbf ./$OUTPUT_FILENAME/* > /dev/null 2>&1
    else
        warning "'$OUTPUT_FILENAME' appears to be unpacked - ignoring!"
    fi
    echo $OUTPUT_FILENAME
}

warning() {
    >&2 echo $1
}

#################
# Demo map data is available in buckets named z12 and z15.
# Note: z12 is just a name (it could have any number of zoom levels)
#
# Requires:
# > Z2_DOWNLOAD_LOCATION  - e.g. https://your-domain.com/app_Z2.mbtiles
# > Z12_DOWNLOAD_LOCATION - e.g. https://your-domain.com/app_Z12.mbtiles
# > Z15_DOWNLOAD_LOCATION - e.g. https://your-domain.com/app_Z15.mbtiles
# > WWW_DATA              - e.g. https://yourserver.com/www.tar.gz
# Note: please create the WWW_DATA using something like: tar -czvf www.tar.gz -C www .
#################
echo Starting Workflow

if ! [ -x "$(command -v mb-util)" ]; then
  echo 'Error: mb-util is not installed.  Try: whalebrew install jskeates/mbutil' >&2
  exit 1
fi

if ! [ -x "$(command -v mbgl-offline)" ]; then
  echo 'Error: mbgl-offline is not installed.  Try: whalebrew install ordnancesurvey/whalebrew-mbgl-offline' >&2
  exit 1
fi

if ! [ -d  www_server ]; then
  echo No directory
  echo Executing Z2
  echo explode $Z2_DOWNLOAD_LOCATION z2_temp
  explode $Z2_DOWNLOAD_LOCATION z2_temp
  echo Executing Z12
  explode $Z12_DOWNLOAD_LOCATION z12_temp
  echo Executing Z15
  explode $Z15_DOWNLOAD_LOCATION z15_temp
  echo Executing WWW
  explode $WWW_DATA www

  echo WWW Server: adding z2
  mv -f z2_temp/* ./www/data/z2/
  rm -Rf z2_temp

  echo WWW Server: adding z12
  mv -f z12_temp/* ./www/data/z12/
  rm -Rf z12_temp

  echo WWW Server: adding z15
  mv -f z15_temp/* ./www/data/z15/
  rm -Rf z15_temp
fi
