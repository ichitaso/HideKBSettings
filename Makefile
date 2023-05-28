DEBUG = 0
FINALPACKAGE = 1

INSTALL_TARGET_PROCESSES = SpringBoard

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
ARCHS = arm64 arm64e
TARGET = iphone:16.2:15.0
else
ARCHS = arm64 arm64e
TARGET = iphone:12.1.2:11.0
endif

THEOS_DEVICE_IP = 127.0.0.1 -p 2222

TWEAK_NAME = HideKBSettings
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_FRAMEWORKS = UIKit

SUBPROJECTS += Preferences

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
