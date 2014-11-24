ARCHS = armv7 arm64
#CFLAGS = -fobjc-arc
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TouchIDEverywhere
TouchIDEverywhere_FILES = Tweak.xm UICKeyChainStore.m UITextField.xm TIDEBioServer.mm HTMLTextField.xm
TouchIDEverywhere_FRAMEWORKS = QuartzCore UIKit Security
TouchIDEverywhere_PRIVATE_FRAMEWORKS = BiometricKit

include $(THEOS_MAKE_PATH)/tweak.mk

#after-install::
#	install.exec "killall -9 SpringBoard"
