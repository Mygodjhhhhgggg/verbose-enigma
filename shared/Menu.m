#import <UIKit/UIKit.h>
#import "Menu.h"
#import "Globals.h"

@interface MenuWindow : UIWindow @end
@implementation MenuWindow
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    UIView *v = [super hitTest:p withEvent:e];
    return v == self.rootViewController.view ? nil : v;
}
@end

static MenuWindow *win;
static UIButton *fab;
static UIView *panel;

static void toggle(void);
static void drag(UIPanGestureRecognizer *g);

static void mk_switch(CGFloat y, NSString *title, BOOL *target) {
    UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectMake(160, y, 51, 31)];
    s.on = *target;
    [s addAction:[UIAction actionWithHandler:^(UIAction *a) {
        *target = ((UISwitch *)a.sender).on;
    }] forControlEvents:UIControlEventValueChanged];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(12, y + 4, 140, 20)];
    l.text = title; l.font = [UIFont systemFontOfSize:13]; l.textColor = UIColor.whiteColor;
    [panel addSubview:l]; [panel addSubview:s];
}

static void build_panel(void) {
    panel = [[UIView alloc] initWithFrame:CGRectMake(fab.center.x + 34, fab.center.y - 30, 226, 300)];
    panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.94];
    panel.layer.cornerRadius = 14;
    panel.hidden = YES;
    [win addSubview:panel];

    UILabel *h = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, 200, 18)];
    h.text = @"CrewMate+"; h.textColor = UIColor.greenColor;
    h.font = [UIFont boldSystemFontOfSize:15];
    [panel addSubview:h];

    UILabel *sl = [[UILabel alloc] initWithFrame:CGRectMake(12, 40, 200, 18)];
    sl.text = @"Speed"; sl.font = [UIFont systemFontOfSize:13]; sl.textColor = UIColor.whiteColor;
    [panel addSubview:sl];

    UISlider *sp = [[UISlider alloc] initWithFrame:CGRectMake(12, 60, 200, 30)];
    sp.minimumValue = 0.5; sp.maximumValue = 5.0; sp.value = 1.0;
    [sp addAction:[UIAction actionWithHandler:^(UIAction *a) {
        g_speed = ((UISlider *)a.sender).value;
    }] forControlEvents:UIControlEventValueChanged];
    [panel addSubview:sp];

    mk_switch(96,  @"Crewmate ESP", &g_espCrew);
    mk_switch(130, @"Impostor ESP", &g_espImp);
    mk_switch(164, @"Names",        &g_espName);
    mk_switch(198, @"Distance",     &g_espDist);
    mk_switch(232, @"Noclip",       &g_noclip);
    mk_switch(266, @"Max vision",   &g_maxVision);
}

void Menu_Setup(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (win) return;
        win = [[MenuWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        win.backgroundColor = UIColor.clearColor;
        win.windowLevel = UIWindowLevelNormal + 200;
        win.rootViewController = [UIViewController new];
        win.hidden = NO;
        if (@available(iOS 13, *))
            win.windowScene = (UIWindowScene *)UIApplication.sharedApplication.connectedScenes.anyObject;

        fab = [UIButton buttonWithType:UIButtonTypeCustom];
        fab.frame = CGRectMake(18, 120, 52, 52);
        fab.backgroundColor = [UIColor colorWithRed:0.1 green:0.75 blue:0.4 alpha:0.9];
        fab.layer.cornerRadius = 26;
        fab.titleLabel.font = [UIFont boldSystemFontOfSize:22];
        [fab setTitle:@"C" forState:UIControlStateNormal];
        [fab addTarget:nil action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
        [win addSubview:fab];

        [fab addGestureRecognizer:[[UIPanGestureRecognizer alloc]
            initWithTarget:nil action:@selector(drag:)]];

        build_panel();
    });
}

static void toggle(void) { panel.hidden = !panel.hidden; }

static void drag(UIPanGestureRecognizer *g) {
    CGPoint t = [g translationInView:win];
    fab.center = CGPointMake(fab.center.x + t.x, fab.center.y + t.y);
    [g setTranslation:CGPointZero inView:win];
    panel.frame = CGRectMake(fab.center.x + 34, fab.center.y - 30, 226, panel.frame.size.height);
}
