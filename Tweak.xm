#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <objc/runtime.h>
#include <pthread.h>
#include <unistd.h>
#include <math.h>
#include "il2cpp.h"
#include "Globals.h"
#import "ESP.h"
#import "Menu.h"

#define TARGET_BUNDLE "com.innersloth.spacemafia"

float g_speed = 1.0f;
BOOL g_noclip = NO, g_espCrew = NO, g_espImp = NO, g_espDist = NO, g_espName = YES, g_maxVision = NO;
BOOL g_inGame = NO;

static Il2CppClass *cPlayerControl, *cPlayerPhysics, *cGameData, *cPlayerInfo,
                  *cCamera, *cVector3, *cShipStatus, *cComponent;
static MethodInfo *mLocalPlayer, *mCamMain, *mW2S, *mGetTransform, *mGetPosition,
                  *mSetEnabled, *mGameInstance, *mShipInstance;
static int oMyPhysics = -1, oSpeed = -1, oCollider = -1, oAllPlayers = -1,
           oPlayerId = -1, oPlayerName = -1, oIsImpostor = -1, oObject = -1, oMaxLight = -1;
static void (*orig_PhysFixed)(void *, void *);

typedef struct { float x, y, z; } Vec3;

static Il2CppClass *cls(const char *ns, const char *n) {
    Il2CppDomain *d = g_il2.domain_get();
    if (!d) return NULL;
    size_t c = 0;
    const Il2CppAssembly **a = g_il2.domain_get_assemblies(d, &c);
    if (!a) return NULL;
    for (size_t i = 0; i < c; i++) {
        Il2CppClass *k = g_il2.class_from_name(g_il2.assembly_get_image(a[i]), ns, n);
        if (k) return k;
    }
    return NULL;
}
static MethodInfo *meth(Il2CppClass *k, const char *n, int argc) {
    return k ? (MethodInfo *)g_il2.class_get_method_from_name(k, n, argc) : NULL;
}
static int fld(Il2CppClass *k, const char *n) {
    FieldInfo *f = k ? g_il2.class_get_field_from_name(k, n) : NULL;
    return f ? (int)g_il2.field_get_offset(f) : -1;
}
static Il2CppObject *invoke(MethodInfo *m, void *obj, void **params) {
    return m ? g_il2.runtime_invoke(m, obj, params, NULL) : NULL;
}
static Il2CppObject *local_player(void) { return invoke(mLocalPlayer, NULL, NULL); }

static Vec3 obj_position(Il2CppObject *obj) {
    Vec3 out = {0, 0, 0};
    if (!obj) return out;
    Il2CppObject *tr = invoke(mGetTransform, obj, NULL);
    if (!tr) return out;
    Il2CppObject *box = invoke(mGetPosition, tr, NULL);
    if (box) out = *(Vec3 *)((char *)box + 0x10);
    return out;
}
static NSString *il2str(Il2CppObject *s) {
    if (!s) return @"";
    int len = *(int *)((char *)s + 0x10);
    if (len <= 0 || len > 64) return @"";
    return [[NSString alloc] initWithBytes:(char *)s + 0x14
                                    length:len * 2
                                  encoding:NSUTF16LittleEndianStringEncoding] ?: @"";
}

static void hook_PhysFixed(void *self, void *mi) {
    Il2CppObject *lp = local_player();
    if (lp && oSpeed >= 0 && *(void **)((char *)lp + oMyPhysics) == self)
        *(float *)((char *)self + oSpeed) = 2.5f * g_speed;
    orig_PhysFixed(self, mi);
}

static void tick(void) {
    Il2CppObject *gd = invoke(mGameInstance, NULL, NULL);
    if (!gd) { if (g_inGame) { g_inGame = NO; ESP_Hide(); } return; }
    g_inGame = YES;

    Il2CppObject *lp = local_player();
    if (!lp) return;

    if (g_noclip && oCollider >= 0) {
        Il2CppObject *col = *(Il2CppObject **)((char *)lp + oCollider);
        if (col) { Il2CppObject *no = NULL; invoke(mSetEnabled, col, (void **)&no); }
    }
    if (g_maxVision && mShipInstance && oMaxLight >= 0) {
        Il2CppObject *ship = invoke(mShipInstance, NULL, NULL);
        if (ship) *(float *)((char *)ship + oMaxLight) = 30.0f;
    }
    if (!g_espCrew && !g_espImp) { ESP_Hide(); return; }

    Il2CppObject *list = *(Il2CppObject **)((char *)gd + oAllPlayers);
    if (!list) return;
    int count = *(int *)((char *)list + 0x18);
    Il2CppObject *items = *(Il2CppObject **)((char *)list + 0x10);
    if (!items || count <= 0) return;

    Il2CppObject *cam = invoke(mCamMain, NULL, NULL);
    if (!cam) return;

    Vec3 me = obj_position(lp);
    NSMutableArray *out = [NSMutableArray array];
    CGFloat H = UIScreen.mainScreen.bounds.size.height;
    CGFloat sc = UIScreen.mainScreen.scale;

    for (int i = 0; i < count; i++) {
        Il2CppObject *info = *(Il2CppObject **)((char *)items + 0x20 + i * sizeof(void *));
        if (!info) continue;
        Il2CppObject *obj = *(Il2CppObject **)((char *)info + oObject);
        if (!obj || obj == lp) continue;
        BOOL imp = *(bool *)((char *)info + oIsImpostor);
        if (imp ? !g_espImp : !g_espCrew) continue;

        Vec3 p = obj_position(obj);
        Il2CppObject *box = g_il2.object_new(cVector3);
        *(Vec3 *)((char *)box + 0x10) = p;
        void *params[1] = { box };
        Il2CppObject *res = invoke(mW2S, cam, params);
        if (!res) continue;
        Vec3 s = *(Vec3 *)((char *)res + 0x10);
        if (s.z <= 0.1f) continue;

        CGFloat dist = sqrtf((p.x - me.x) * (p.x - me.x) + (p.y - me.y) * (p.y - me.y));
        [out addObject:@{
            @"pos":  [NSValue valueWithCGPoint:CGPointMake(s.x / sc, (H - s.y / sc))],
            @"size": @(MAX(24.0, MIN(150.0, 900.0 / MAX(dist, 1.0)))),
            @"name": il2str(*(Il2CppObject **)((char *)info + oPlayerName)),
            @"dist": [NSString stringWithFormat:@"%.0fm", dist],
            @"imp":  @(imp)
        }];
    }
    ESP_Update(out);
}

static void *tick_thread(void *arg) {
    g_il2.thread_attach(g_il2.domain_get());
    for (;;) { @autoreleasepool { tick(); } usleep(80000); }
    return NULL;
}

static BOOL resolve_all(void) {
    g_il2.thread_attach(g_il2.domain_get());
    cPlayerControl = cls("", "PlayerControl");
    cPlayerPhysics = cls("", "PlayerPhysics");
    cGameData      = cls("", "GameData");
    cPlayerInfo    = cls("", "PlayerInfo");
    cShipStatus    = cls("", "ShipStatus");
    cCamera        = cls("UnityEngine", "Camera");
    cVector3       = cls("UnityEngine", "Vector3");
    cComponent     = cls("UnityEngine", "Component");

    if (!cPlayerControl || !cPlayerPhysics || !cGameData || !cPlayerInfo || !cCamera) {
        NSLog(@"[CrewMate+] resolve incomplete");
        return NO;
    }
    mLocalPlayer  = meth(cPlayerControl, "get_LocalPlayer", 0);
    mGameInstance = meth(cGameData, "get_Instance", 0);
    mCamMain      = meth(cCamera, "get_main", 0);
    mGetTransform = meth(cComponent, "get_transform", 0);
    mGetPosition  = meth(cls("UnityEngine", "Transform"), "get_position", 0);
    mW2S          = meth(cCamera, "WorldToScreenPoint", 1);
    mSetEnabled   = meth(cls("UnityEngine", "Behaviour"), "set_enabled", 1);

    oMyPhysics  = fld(cPlayerControl, "MyPhysics");
    oCollider   = fld(cPlayerControl, "Collider");
    oSpeed      = fld(cPlayerPhysics, "Speed");
    oAllPlayers = fld(cGameData, "AllPlayers");
    oPlayerId   = fld(cPlayerInfo, "PlayerId");
    oPlayerName = fld(cPlayerInfo, "PlayerName");
    oIsImpostor = fld(cPlayerInfo, "IsImpostor");
    oObject     = fld(cPlayerInfo, "Object");
    if (cShipStatus) {
        mShipInstance = meth(cShipStatus, "get_Instance", 0);
        oMaxLight     = fld(cShipStatus, "MaxLightRadius");
    }

    MethodInfo *fixedUp = meth(cPlayerPhysics, "FixedUpdate", 0);
    if (fixedUp)
        MSHookFunction(*(void **)fixedUp, (void *)hook_PhysFixed, (void **)&orig_PhysFixed);

    NSLog(@"[CrewMate+] resolved speed=%d collider=%d players=%d", oSpeed, oCollider, oAllPlayers);
    return (oSpeed >= 0 && oAllPlayers >= 0);
}

static void *boot(void *arg) {
    if (il2_init() != 0) { NSLog(@"[CrewMate+] no il2cpp symbols"); return NULL; }
    for (int i = 0; i < 600 && !g_il2.domain_get(); i++) usleep(100000);
    if (!g_il2.domain_get()) return NULL;
    while (!resolve_all()) usleep(500000);
    pthread_t t;
    pthread_create(&t, NULL, tick_thread, NULL);
    return NULL;
}

static void (*orig_didFinish)(id, SEL, UIApplication *, NSDictionary *);

static BOOL hook_didFinish(id self, SEL _cmd, UIApplication *app, NSDictionary *opts) {
    BOOL r = orig_didFinish(self, _cmd, app, opts);
    ESP_Setup();
    Menu_Setup();
    return r;
}

static void swizzle_delegate(id del) {
    if (!del || orig_didFinish) return;
    Class k = object_getClass(del);
    SEL sel = @selector(application:didFinishLaunchingWithOptions:);
    Method m = class_getInstanceMethod(k, sel);
    if (!m) return;
    orig_didFinish = (void *)method_getImplementation(m);
    class_replaceMethod(k, sel, (IMP)hook_didFinish, method_getTypeEncoding(m));
    NSLog(@"[CrewMate+] delegate %s swizzled", class_getName(k));
}

static void (*orig_setDelegate)(id, SEL, id);
static void hook_setDelegate(id self, SEL _cmd, id del) {
    orig_setDelegate(self, _cmd, del);
    swizzle_delegate(del);
}

__attribute__((constructor)) static void init(void) {
    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@(TARGET_BUNDLE)]) return;

    SEL sel = @selector(setDelegate:);
    Method m = class_getInstanceMethod(objc_getClass("UIApplication"), sel);
    if (m) {
        orig_setDelegate = (void *)method_getImplementation(m);
        class_replaceMethod(objc_getClass("UIApplication"), sel, (IMP)hook_setDelegate, method_getTypeEncoding(m));
    }
    swizzle_delegate(UIApplication.sharedApplication.delegate);

    pthread_t t;
    pthread_create(&t, NULL, boot, NULL);
}