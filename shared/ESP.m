#import <UIKit/UIKit.h>
#import "ESP.h"
#import "Globals.h"

@interface ESPWindow : UIWindow @end
@implementation ESPWindow
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e { return nil; }
@end

static ESPWindow *win;
static NSMutableArray<UIView *> *pool;

static void ensure_window(void) {
    if (win) return;
    win = [[ESPWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    win.backgroundColor = UIColor.clearColor;
    win.windowLevel = UIWindowLevelNormal + 100;
    win.rootViewController = [UIViewController new];
    win.hidden = NO;
    if (@available(iOS 13, *))
        win.windowScene = (UIWindowScene *)UIApplication.sharedApplication.connectedScenes.anyObject;
    pool = [NSMutableArray array];
}

static UIView *slot(NSUInteger i) {
    while (pool.count <= i) {
        UIView *c = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        c.layer.borderWidth = 1.2;
        c.userInteractionEnabled = NO;
        UILabel *n = [[UILabel alloc] initWithFrame:CGRectMake(-35, -15, 150, 13)];
        n.tag = 1; n.font = [UIFont boldSystemFontOfSize:9];
        n.textAlignment = NSTextAlignmentCenter;
        UILabel *d = [[UILabel alloc] initWithFrame:CGRectMake(-35, 41, 150, 12)];
        d.tag = 2; d.font = [UIFont systemFontOfSize:8];
        d.textAlignment = NSTextAlignmentCenter; d.textColor = UIColor.whiteColor;
        [c addSubview:n]; [c addSubview:d];
        c.hidden = YES;
        [win addSubview:c];
        [pool addObject:c];
    }
    return pool[i];
}

void ESP_Setup(void) { dispatch_async(dispatch_get_main_queue(), ^{ ensure_window(); }); }

void ESP_Hide(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *v in pool) v.hidden = YES;
    });
}

void ESP_Update(NSArray *entries) {
    dispatch_async(dispatch_get_main_queue(), ^{
        ensure_window();
        NSUInteger i = 0;
        for (NSDictionary *e in entries) {
            CGPoint p = [e[@"pos"] CGPointValue];
            CGFloat s = [e[@"size"] doubleValue];
            BOOL imp = [e[@"imp"] boolValue];
            UIView *v = slot(i++);
            v.hidden = NO;
            v.frame = CGRectMake(p.x - s / 2, p.y - s / 2, s, s);
            v.layer.borderColor = (imp ? UIColor.redColor : UIColor.greenColor).CGColor;
            UILabel *n = [v viewWithTag:1];
            UILabel *d = [v viewWithTag:2];
            n.text = g_espName ? e[@"name"] : nil;
            n.textColor = imp ? UIColor.redColor : UIColor.greenColor;
            d.text = g_espDist ? e[@"dist"] : nil;
        }
        for (NSUInteger k = i; k < pool.count; k++) pool[k].hidden = YES;
    });
}
