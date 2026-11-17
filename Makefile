TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = AmongUsMenu
AmongUsMenu_FILES = Tweak.xm shared/il2cpp.m shared/ESP.m shared/Menu.m
AmongUsMenu_CFLAGS = -fobjc-arc -Ishared
AmongUsMenu_FRAMEWORKS = UIKit Foundation
AmongUsMenu_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/library.mk