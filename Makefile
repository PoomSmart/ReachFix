SDKVERSION = 8.0
ARCHS = armv7
GO_EASY_ON_ME = 1

include theos/makefiles/common.mk
TWEAK_NAME = ReachFix
ReachFix_FILES = Tweak.xm
ReachFix_PRIVATE_FRAMEWORKS = Preferences
ReachFix_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk
