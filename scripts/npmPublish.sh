#!/bin/bash

# Publishes the current version

BASE_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

echoe() {
  # find all colors here: https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux#5947802
  # Reset
  Color_Off='\033[0m'       # Text Reset

  # Bold High Intensity
  BIBlack='\033[1;90m'      # Black
  
  # High Intensity backgrounds
  On_IYellow='\033[0;103m'  # Yellow

  echo ""
  echo ""
  echo -e "${On_IYellow}${BIBlack}${1}${Color_Off}"
  echo ""
}

if [ "$TRAVIS" = "true" ]; then
  # setup token when running in travis
  echo "//registry.npmjs.org/:_authToken=${NPM_AUTH_TOKEN}" > ~/.npmrc
fi


#### LUIGI CLIENT
cd $BASE_DIR/../client
NAME=$(node -p "require('./package.json').name")
VERSION=$(node -p "require('./package.json').version")
echo "Processing $NAME"

# Check if it can be published (github release must exist)
NOT_YET_RELEASED=`git tag -l "v$VERSION"`
if [ "$NOT_YET_RELEASED" = "" ]; then
  echo "Tag (github release) does not exist, not going to publish $VERSION to npm"
  exit 0;
fi

# Check if was published already
NPM_GREP=`npm info $NAME versions | grep "'$VERSION'" | wc -l`
if [[ "$NPM_GREP" =~ "1" ]]; then
  echo "$VERSION already published, waiting for next release."
else

  echoe "Installing and bundling Luigi Client"
  cd $BASE_DIR/../client
  npm ci
  npm run bundle

  echoe "Publishing Luigi Client"
  cd $BASE_DIR/../client
  npm publish --access public
  if [[ $VERSION != *"rc."* ]]; then
    echo "Tag $VERSION with latest"
    npm dist-tag add $NAME@$VERSION latest
  fi

fi # end NPM_GREP client



#### LUIGI CORE
cd $BASE_DIR/../core/public
NAME=$(node -p "require('./package.json').name")
VERSION=$(node -p "require('./package.json').version")
echo "Processing $NAME"

# Check if it can be published (github release must exist)
NOT_YET_RELEASED=`git tag -l "v$VERSION"`
if [ "$NOT_YET_RELEASED" = "" ]; then
  echo "Tag (github release) does not exist, not going to publish $NAME@$VERSION to npm"
  exit 0;
fi

# Check if was published already
NPM_GREP=`npm info $NAME versions | grep "'$VERSION'" | wc -l`
if [[ "$NPM_GREP" =~ "1" ]]; then
  echo "$VERSION already published, waiting for next release."
else

  echoe "Installing and bundling Luigi Core"
  cd $BASE_DIR/../core
  npm ci
  npm run bundle

  echoe "Publishing Luigi Core"
  cd $BASE_DIR/../core/public
  npm publish --access public

  cd $BASE_DIR/../core
  if [[ $VERSION != *"rc."* ]]; then
    echo "Tag $VERSION with latest"
    npm dist-tag add $NAME@$VERSION latest
  fi
fi # end NPM_GREP core



if [ "$TRAVIS" = "true" ]; then
  # setup token when running in travis
  echo "" > ~/.npmrc
fi