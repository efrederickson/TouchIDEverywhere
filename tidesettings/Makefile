ARCHS = armv7 armv7s arm64
CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = TIDESettings
TIDESettings_FILES = TIDESettings.mm $(shell find $(THEOS)/include/SettingsKit -name '*.m')
TIDESettings_INSTALL_PATH = /Library/PreferenceBundles
TIDESettings_FRAMEWORKS = UIKit MessageUI Social QuartzCore CoreGraphics
TIDESettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)cp $(THEOS)/include/SettingsKit/Resources/*.png $(THEOS_STAGING_DIR)/Library/PreferenceBundles/TIDESettings.bundle/$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/TIDESettings.plist$(ECHO_END)
