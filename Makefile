DEBUG = 0
GO_EASY_ON_ME := 1
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
ARCHS = arm64 arm64e

TARGET = iphone:12.1.2:11.0

THEOS_DEVICE_IP = 127.0.0.1 -p 2222

TWEAK_NAME = HideKBSettings
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_FRAMEWORKS = UIKit

SUBPROJECTS += Preferences

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

SUDO = sudo
ifneq ($(_THEOS_PLATFORM),Darwin)
	SUDO = echo "WARNING: Permissions will be broken on all non-OS X/iOS build environments.";exit;
endif

before-package::
	@$(SUDO) chown -R root:wheel $(THEOS_STAGING_DIR)
	@$(SUDO) chmod -R 755 $(THEOS_STAGING_DIR)
	@$(SUDO) chmod 666 $(THEOS_STAGING_DIR)/DEBIAN/control

after-package::
	@make clean
	@$(SUDO) mv .theos/_ $(THEOS_PACKAGE_NAME)_$(THEOS_PACKAGE_BASE_VERSION)_iphoneos-arm
	@$(SUDO) rm -rf .theos/_
	@zip -r .theos/$(THEOS_PACKAGE_NAME)_$(THEOS_PACKAGE_BASE_VERSION)_iphoneos-arm.zip $(THEOS_PACKAGE_NAME)_$(THEOS_PACKAGE_BASE_VERSION)_iphoneos-arm
	@mv .theos/$(THEOS_PACKAGE_NAME)_$(THEOS_PACKAGE_BASE_VERSION)_iphoneos-arm.zip ./
	@$(SUDO) rm -rf $(THEOS_PACKAGE_NAME)_$(THEOS_PACKAGE_BASE_VERSION)_iphoneos-arm

after-install::
	install.exec "killall backboardd"