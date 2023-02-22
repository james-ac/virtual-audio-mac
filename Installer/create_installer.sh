#!/usr/bin/env bash

# run for BlackHole directory.

# create installer for different channel versions

# for channels in 2 16 64 128 256
for channels in 2
do

ch=$channels"ch"
driverName="AeriCast"
version=`git describe --tags --abbrev=0`
bundleID="virtual-audio.com.$driverName$ch"
icon="AeriCast.icns"

# Build
xcodebuild \
-project BlackHole.xcodeproj \
-configuration Release \
-target AeriCast CONFIGURATION_BUILD_DIR=build \
PRODUCT_BUNDLE_IDENTIFIER=$bundleID \
GCC_PREPROCESSOR_DEFINITIONS='$GCC_PREPROCESSOR_DEFINITIONS
kNumber_Of_Channels='$channels'
kPlugIn_BundleID=\"'$bundleID'\"
kDriver_Name=\"'$driverName'\"
kPlugIn_Icon=\"'$icon'\"'

# Generate a new UUID
uuid=$(uuidgen)
awk '{sub(/e395c745-4eea-4d94-bb92-46224221047c/,"'$uuid'")}1' build/AeriCast.driver/Contents/Info.plist > Temp.plist
mv Temp.plist build/AeriCast.driver/Contents/Info.plist

mkdir installer/root
mv build/AeriCast.driver installer/root/$driverName$ch.driver
rm -r build

# Sign
codesign --force --deep --options runtime --sign "Developer ID Application: AeriCast Inc (TP685V6M24)" Installer/root/$driverName$ch.driver

# Create package with pkgbuild
chmod 755 Installer/Scripts/preinstall
chmod 755 Installer/Scripts/postinstall

pkgbuild --sign "Developer ID Installer: AeriCast Inc (TP685V6M24)" --root Installer/root --scripts Installer/Scripts --install-location /Library/Audio/Plug-Ins/HAL Installer/AeriCast.pkg
rm -r Installer/root

# Create installer with productbuild
cd Installer

echo "<?xml version=\"1.0\" encoding='utf-8'?>
<installer-gui-script minSpecVersion='2'>
    <title>$driverName: Virtual Audio Driver $ch $version</title>
    <welcome file='welcome.html'/>
    <license file='../LICENSE'/>
    <conclusion file='conclusion.html'/>
    <domains enable_anywhere='false' enable_currentUserHome='false' enable_localSystem='true'/>
    <pkg-ref id=\"$bundleID\"/>
    <options customize='never' require-scripts='false' hostArchitectures='x86_64,arm64'/>
    <volume-check>
        <allowed-os-versions>
            <os-version min='10.9'/>
        </allowed-os-versions>
    </volume-check>
    <choices-outline>
        <line choice=\"$bundleID\"/>
    </choices-outline>
    <choice id=\"$bundleID\" visible='true' title=\"$driverName $ch\" start_selected='true'>
        <pkg-ref id=\"$bundleID\"/>
    </choice>
    <pkg-ref id=\"$bundleID\" version=\"$version\" onConclusion='none'>AeriCast.pkg</pkg-ref>
</installer-gui-script>" >> distribution.xml


productbuild --sign "Developer ID Installer: AeriCast Inc (TP685V6M24)" --distribution distribution.xml --resources . --package-path BlackHole.pkg $driverName$ch.$version.pkg
rm distribution.xml
rm -f AeriCast.pkg

# Notarize
xcrun notarytool submit $driverName$ch.$version.pkg --team-id "TP685V6M24" --progress --wait --keychain-profile "notarize"

xcrun stapler staple $driverName$ch.$version.pkg

cd ..

done
