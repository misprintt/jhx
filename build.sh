##  Build script
set -e

mkdir -p bin
rm -rf bin/*

mkdir bin/example
mkdir bin/test

haxelib run munit test -coverage

haxe build.hxml

cp -rf example/resource/ bin/example/

osascript refreshChrome.scpt

