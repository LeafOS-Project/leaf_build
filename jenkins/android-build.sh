#!/bin/bash

set -e

LEAF_FLAVORS=(VANILLA GMS microG)
TARGET_FILES_DIR="/var/lib/jenkins/leaf/target-files/$RELEASE_DIR$JENKINS_DEVICE"
MASTER_IP="10.2.0.1"
DL_DIR="/var/www/dl.leafos.org/$RELEASE_DIR$JENKINS_DEVICE"
KEY_DIR="/var/lib/jenkins/.android-certs"
AVB_ALGORITHM="SHA256_RSA4096"
export LEAF_BUILDTYPE="OFFICIAL"
export BOARD_EXT4_SHARE_DUP_BLOCKS=true
export TARGET_RO_FILE_SYSTEM_TYPE="erofs"
export OVERRIDE_TARGET_FLATTEN_APEX=true

if [ "$JENKINS_RELEASETYPE" = "Alpha" ]; then
	RELEASE_DIR="alpha/"
elif [ "$JENKINS_RELEASETYPE" = "Beta" ]; then
	RELEASE_DIR="beta/"
fi

function sync() {
	repo init -u https://git.leafos.org/LeafOS-Project/android -b leaf-2.0 --depth=1
	repo sync -j"$(nproc)" --force-sync
}

function target-files() {
	source build/envsetup.sh
	fetch_device "$JENKINS_DEVICE"
	lunch "$JENKINS_TARGET"
	for JENKINS_FLAVOR in "${LEAF_FLAVORS[@]}"; do
		unset WITH_GMS
		unset WITH_MICROG
		if [ "$JENKINS_FLAVOR" = "GMS" ]; then
			export WITH_GMS=true
		elif [ "$JENKINS_FLAVOR" = "microG" ]; then
			export WITH_MICROG=true
		fi
		rm -rf "$OUT"
		m -j"$(nproc)" target-files-package otatools
		mv "$OUT/obj/PACKAGING/target_files_intermediates/$TARGET_PRODUCT-target_files-$BUILD_ID.zip" \
			"out/$JENKINS_DEVICE-target_files-$JENKINS_FLAVOR-$BUILD_ID.zip"
	done
}

function sign() {
	mkdir -p "/var/lib/jenkins/leaf/target-files/$RELEASE_DIR$JENKINS_DEVICE"
	for JENKINS_FLAVOR in "${LEAF_FLAVORS[@]}"; do
		./out/host/linux-x86/bin/sign_target_files_apks -o -d "$KEY_DIR" --avb_vbmeta_key "$KEY_DIR/avb.pem" --avb_vbmeta_algorithm "$AVB_ALGORITHM" \
			--extra_apks AdServicesApk.apk="$KEY_DIR/releasekey" \
			--extra_apks Bluetooth.apk="$KEY_DIR/bluetooth" \
			--extra_apks HalfSheetUX.apk="$KEY_DIR/releasekey" \
			--extra_apks OsuLogin.apk="$KEY_DIR/releasekey" \
			--extra_apks SafetyCenterResources.apk="$KEY_DIR/releasekey" \
			--extra_apks ServiceConnectivityResources.apk="$KEY_DIR/releasekey" \
			--extra_apks ServiceUwbResources.apk="$KEY_DIR/releasekey" \
			--extra_apks ServiceWifiResources.apk="$KEY_DIR/releasekey" \
			--extra_apks WifiDialog.apk="$KEY_DIR/releasekey" \
			--extra_apks com.android.adbd.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.adbd.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.adservices.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.adservices.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.apex.cts.shim.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.apex.cts.shim.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.appsearch.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.appsearch.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.art.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.art.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.art.debug.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.art.debug.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.btservices.apex="$KEY_DIR/bluetooth" \
			--extra_apex_payload_key com.android.btservices.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.cellbroadcast.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.cellbroadcast.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.compos.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.compos.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.conscrypt.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.conscrypt.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.extservices.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.extservices.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.i18n.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.i18n.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.ipsec.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.ipsec.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.media.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.media.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.media.swcodec.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.media.swcodec.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.mediaprovider.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.mediaprovider.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.neuralnetworks.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.neuralnetworks.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.ondevicepersonalization.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.ondevicepersonalization.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.os.statsd.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.os.statsd.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.permission.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.permission.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.resolv.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.resolv.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.runtime.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.runtime.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.scheduling.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.scheduling.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.sdkext.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.sdkext.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.tethering.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.tethering.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.tzdata.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.tzdata.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.uwb.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.uwb.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.virt.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.virt.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.vndk.current.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.vndk.current.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.android.wifi.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.android.wifi.apex="$KEY_DIR/avb.pem" \
			--extra_apks com.google.pixel.camera.hal.apex="$KEY_DIR/releasekey" \
			--extra_apex_payload_key com.google.pixel.camera.hal.apex="$KEY_DIR/avb.pem" \
			"out/$JENKINS_DEVICE-target_files-$JENKINS_FLAVOR-$BUILD_ID.zip" \
			"$TARGET_FILES_DIR/$JENKINS_DEVICE-target_files-$JENKINS_FLAVOR-$BUILD_ID-signed.zip"
	done
}

function ota-pakcage() {
	for JENKINS_FLAVOR in "${LEAF_FLAVORS[@]}"; do
		./out/host/linux-x86/bin/ota_from_target_files -k "$KEY_DIR/releasekey" \
			"$TARGET_FILES_DIR/$JENKINS_DEVICE-target_files-$JENKINS_FLAVOR-$BUILD_ID-signed.zip" \
			"$JENKINS_DEVICE-ota-$JENKINS_FLAVOR-$BUILD_ID.zip"
		# Incremental OTA
		if [ -f "$TARGET_FILES_DIR/$(cat "$TARGET_FILES_DIR/latest_$JENKINS_FLAVOR" 2>/dev/null)" ]; then
			./out/host/linux-x86/bin/ota_from_target_files -k "$KEY_DIR/releasekey" \
				-i "$TARGET_FILES_DIR/$(cat "$TARGET_FILES_DIR/latest_$JENKINS_FLAVOR")" \
				"$TARGET_FILES_DIR/$JENKINS_DEVICE-target_files-$JENKINS_FLAVOR-$BUILD_ID-signed.zip" \
				"$JENKINS_DEVICE-incremental-ota-$JENKINS_FLAVOR-$BUILD_ID.zip"
		fi
	done
}

function upload() {
	ssh jenkins@$MASTER_IP mkdir -p "$DL_DIR"
	for JENKINS_FLAVOR in "${LEAF_FLAVORS[@]}"; do
		scp "$JENKINS_DEVICE-ota-$JENKINS_FLAVOR-$BUILD_ID.zip" "jenkins@$MASTER_IP:$DL_DIR"
		if [ -f "$JENKINS_DEVICE-incremental-ota-$JENKINS_FLAVOR-$BUILD_ID.zip" ]; then
			scp "$JENKINS_DEVICE-incremental-ota-$JENKINS_FLAVOR-$BUILD_ID.zip" "jenkins@$MASTER_IP:$DL_DIR"
			rm -f "$TARGET_FILES_DIR/$(cat "$TARGET_FILES_DIR/latest_$JENKINS_FLAVOR")"
		fi
		unzip -p "$TARGET_FILES_DIR/$JENKINS_DEVICE-target_files-$JENKINS_FLAVOR-$BUILD_ID-signed.zip" IMAGES/recovery.img >"$JENKINS_DEVICE-recovery-$JENKINS_FLAVOR-$BUILD_ID.img"
		scp "$JENKINS_DEVICE-recovery-$JENKINS_FLAVOR-$BUILD_ID.img" "jenkins@$MASTER_IP:$DL_DIR"
		echo "$JENKINS_DEVICE-target_files-$JENKINS_FLAVOR-$BUILD_ID-signed.zip" >"$TARGET_FILES_DIR/latest_$JENKINS_FLAVOR"
	done
}

function cleanup() {
	rm -rf out
	rm -f -- *-ota-*.zip
	rm -f -- *-recovery-*.img
	rm -rf .repo/local_manifests
}
