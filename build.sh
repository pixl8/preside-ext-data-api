#!/bin/bash

GIT_BRANCH=${CI_COMMIT_REF_NAME:-unknown-branch}
BRANCH_FOLDER=${GIT_BRANCH//origin\//}
BRANCH_FOLDER="${BRANCH_FOLDER##*/}"
ZIP_FILE=$BRANCH_FOLDER.zip
BUILD_DIR=build/$BRANCH_FOLDER/
BUILD_NUMBER=${CI_BUILD_ID}
PADDED_BUILD_NUMBER=`printf %05d $BUILD_NUMBER`

if [[ $GIT_BRANCH == v* ]] ; then
	VERSION_NUMBER="${GIT_BRANCH//v}.$PADDED_BUILD_NUMBER"
else
	VERSION_NUMBER="${GIT_BRANCH//release-}.$PADDED_BUILD_NUMBER-SNAPSHOT"
fi

echo "Building Preside Extension: Data API"
echo "======================================="
echo "GIT Branch      : $GIT_BRANCH"
echo "Version number  : $VERSION_NUMBER"
echo

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

if [[ -d "assets" && -f "assets/Gruntfile.js" ]]; then
	echo "Compiling static files..."
	cd assets
	npm install || exit 1
	grunt || exit 1
	echo "Done."
	cd ..
fi

echo "Copying files to $BUILD_DIR..."
rsync -a ./ --exclude=".*" --exclude="$BUILD_DIR" --exclude="*.sh" --exclude="**/node_modules" --exclude="*.log" --exclude="tests" "$BUILD_DIR" || exit 1
echo "Done."

cd "$BUILD_DIR"
echo "Installing dependencies..."
box install --production save=false || exit 1
echo "Done."

echo "Inserting version number..."
sed -i "s/VERSION_NUMBER/$VERSION_NUMBER/" manifest.json
sed -i "s/VERSION_NUMBER/$VERSION_NUMBER/" box.json
sed -i "s/DOWNLOAD_LOCATION/$BRANCH_FOLDER/" box.json
echo "Done."

echo "Zipping up..."
zip -rq $ZIP_FILE * -x jmimemagic.log || exit 1
mv $ZIP_FILE ../
cd ../
if [[ $GIT_BRANCH == v* ]] ; then
	cp $ZIP_FILE stable.zip
else
	cp $ZIP_FILE bleeding-edge.zip
fi

rm -rf $BRANCH_FOLDER || exit 1
echo done

echo "Build complete :)"
