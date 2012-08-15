##  Build script
set -e

mkdir -p bin
rm -rf bin/*

mkdir bin/example
mkdir bin/test

haxe build.hxml

cp -rf example/resource/ bin/example/

haxelib run munit test -coverage

osascript refreshChrome.scpt