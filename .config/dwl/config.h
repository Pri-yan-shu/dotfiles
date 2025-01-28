#include <xkbcommon/xkbcommon-keysyms.h>
#define ALT WLR_MODIFIER_ALT
#define SUPER WLR_MODIFIER_LOGO
#define SHIFT WLR_MODIFIER_SHIFT
#define CTRL WLR_MODIFIER_CTRL


/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }
/* appearance */
static const int sloppyfocus               = 1;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;  /* 1 means idle inhibitors will disable idle tracking even if it's surface isn't visible  */
static const unsigned int borderpx         = 0;  /* border pixel of windows */
static const float rootcolor[]             = COLOR(0x000000ff);
static const float bordercolor[]           = COLOR(0x444444ff);
static const float focuscolor[]            = COLOR(0x005577ff);
static const float urgentcolor[]           = COLOR(0xff0000ff);
/* This conforms to the xdg-protocol. Set the alpha to zero to restore the old behavior */
static const float fullscreen_bg[]         = {0.0f, 0.0f, 0.2f, 1.0f}; /* You can also use glsl colors */
// static const float fullscreen_bg[]         = {0.1f, 0.1f, 0.1f, 1.0f}; /* You can also use glsl colors */

/* tagging - TAGCOUNT must be no greater than 31 */
#define TAGCOUNT (9)

/* logging */
static int log_level = WLR_ERROR;

static const Rule rules[] = {
	/* app_id             title       tags mask     isfloating   monitor */
	/* examples: */
	// { "Gimp_EXAMPLE",     NULL,       0,            1,           -1 }, /* Start on currently visible tags floating, not tiled */
	// { "firefox_EXAMPLE",  NULL,       1 << 8,       0,           -1 }, /* Start on ONLY tag "9" */
	{ NULL,     					NULL,       0,            0,           -1 },
};

/* layout(s) */
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },
	// { "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
	{ NULL, NULL}
	// { "<>=",      list_show_wallpaper },
};

/* monitors */
/* NOTE: ALWAYS add a fallback rule, even if you are completely sure it won't be used */
static const MonitorRule monrules[] = {
	/* name       mfact  nmaster scale layout       rotate/reflect                x    y */
	/* example of a HiDPI laptop monitor:
	{ "eDP-1",    0.5f,  1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
  { "HDMI-A-1", 0.5, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, 0,     0,    2560,  1440, 144, 0, 0},
	*/
	{ NULL,       0.5f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1},
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
	/* can specify fields: rules, model, layout, variant, options */
	/* example:
	.options = "ctrl:nocaps",
	*/
	.options = NULL,
};

static const int repeat_rate = 25;
static const int repeat_delay = 600;

/* Trackpad */
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 0;
static const int natural_scrolling = 0;
static const int disable_while_typing = 0;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
/* You can choose between:
LIBINPUT_CONFIG_SCROLL_NO_SCROLL
LIBINPUT_CONFIG_SCROLL_2FG
LIBINPUT_CONFIG_SCROLL_EDGE
LIBINPUT_CONFIG_SCROLL_ON_BUTTON_DOWN
*/
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;

/* You can choose between:
LIBINPUT_CONFIG_CLICK_METHOD_NONE
LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS
LIBINPUT_CONFIG_CLICK_METHOD_CLICKFINGER
*/
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;

/* You can choose between:
LIBINPUT_CONFIG_SEND_EVENTS_ENABLED
LIBINPUT_CONFIG_SEND_EVENTS_DISABLED
LIBINPUT_CONFIG_SEND_EVENTS_DISABLED_ON_EXTERNAL_MOUSE
*/
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;

/* You can choose between:
LIBINPUT_CONFIG_ACCEL_PROFILE_FLAT
LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE
*/
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = 1.0;

/* You can choose between:
LIBINPUT_CONFIG_TAP_MAP_LRM -- 1/2/3 finger tap maps to left/right/middle
LIBINPUT_CONFIG_TAP_MAP_LMR -- 1/2/3 finger tap maps to left/middle/right
*/
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

/* If you want to use the windows key for MODKEY, use WLR_MODIFIER_LOGO */
// #define MODKEY WLR_MODIFIER_ALT

#define WMKEYS(KEY,SKEY,TAG) \
	{ ALT,                    KEY,            view,            {.ui = 1 << TAG} }, \
	{ ALT|SUPER,              KEY,           toggleview,      {.ui = 1 << TAG} }, \
	{ SUPER, 		          KEY,            tag,             {.ui = 1 << TAG} }, \
	{ ALT|SUPER|SHIFT,        SKEY,			  toggletag,	   {.ui = 1 << TAG} }

#define TAGKEYS(KEY,SKEY,TAG) \
	{ ALT,                    KEY,            view,            {.ui = 1 << TAG} }, \
	{ ALT|CTRL,  KEY,            toggleview,      {.ui = 1 << TAG} }, \
	{ ALT|SHIFT, SKEY,           tag,             {.ui = 1 << TAG} }, \
	{ ALT|CTRL|SHIFT,SKEY,toggletag, {.ui = 1 << TAG} }

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static const char *termcmd[] = { "footclient", NULL };
static const char *termapp[] = { "footcmd", NULL};
// static const char *termapp[] = { "/bin/sh", "-c", "footclient", "$(tofi-run)", NULL};
static const char *menucmd[] = { "tofi-drun","--drun-launch=true", NULL };
// static const char *menucmd[] = { "bemenu-run", NULL };

#include "shiftview.c"

static const Key keys[] = {
	/* Note that Shift changes certain key codes: c -> C, 2 -> at, etc. */
	/* modifier                  key                 function        argument */
	{ 0,                    XKB_KEY_XF86AudioMute,spawn,       		SHCMD("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")  },
	{ 0,                    XKB_KEY_XF86AudioRaiseVolume,spawn,     SHCMD("wpctl set-volume @DEFAULT_AUDIO_SINK@ .03+")  },
	{ 0,                    XKB_KEY_XF86AudioLowerVolume,spawn,     SHCMD("wpctl set-volume @DEFAULT_AUDIO_SINK@ .03-")  },
	{ 0,                    XKB_KEY_XF86MonBrightnessUp,spawn,      SHCMD("light -A 15")  },
	{ 0,                    XKB_KEY_XF86MonBrightnessDown,spawn,    SHCMD("light -U 15")  },
	{ 0,                    XKB_KEY_XF86Sleep,spawn,       		    SHCMD("doas zzz > /dev/null")  },
	{ 0,                    XKB_KEY_XF86PowerOff,spawn,       		SHCMD("doas poweroff")  },
	{ 0,                    XKB_KEY_XF86AudioPlay,spawn,       		SHCMD("cmus-remote -u")  },
	{ 0,                    XKB_KEY_XF86AudioNext,spawn,       		SHCMD("cmus-remote -n")  },
	{ 0,                    XKB_KEY_XF86AudioPrev,spawn,       		SHCMD("cmus-remote -r")  },
	{ 0,                    XKB_KEY_Print,spawn,       		        SHCMD("slurp | grim -g- $HOME/media/images/screenshots/$(date -Iseconds).png")  },
	{ 0,                    XKB_KEY_XF86AudioMicMute,spawn,       	SHCMD("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")  },

	{ ALT,                  XKB_KEY_g,          spawn,       		{.v = menucmd} },
	{ ALT,					XKB_KEY_Return,     spawn,          {.v = termcmd} },
	{ ALT,						XKB_KEY_p,      		spawn,          {.v = termapp} },
	{ SUPER,                  XKB_KEY_Left,       setmfact,       {.f = -0.05f} },
	{ SUPER,                  XKB_KEY_Right,      setmfact,       {.f = +0.05f} },
	{ SUPER,                  XKB_KEY_Up,         incnmaster,     {.i = -1} },
	{ SUPER,                  XKB_KEY_Down,       incnmaster,     {.i = +1} },
	{ ALT,                    XKB_KEY_s,          focusstack,     {.i = -1} },
	{ ALT,                    XKB_KEY_t,          focusstack,     {.i = +1} },
	{ ALT,                    XKB_KEY_m,          view,           {0} },
	{ ALT,                   XKB_KEY_bracketright,killclient,     {0} },
	{ ALT,                    XKB_KEY_equal,      nextlayout,     {0} },
	{ ALT,                    XKB_KEY_minus,      zoom,           {0} },
	{ ALT,                    XKB_KEY_space,      setlayout,      {0} },
	// { ALT,                    XKB_KEY_w,          view,           {.ui = ~0} },
	{ ALT,                    XKB_KEY_y,          tag,            {.ui = ~0} },
	{ ALT,                    XKB_KEY_g,      		tagmon,         {.i = WLR_DIRECTION_LEFT} },
	{ ALT,                    XKB_KEY_h,     			tagmon,         {.i = WLR_DIRECTION_RIGHT} },
	{ ALT,                    XKB_KEY_r,          shiftview,     	{.i = +1} },
	{ ALT,                    XKB_KEY_a,          shiftview,     	{.i = -1} },
	
	{ ALT,                    XKB_KEY_y,          togglefloating, {0} },
	{ ALT|SHIFT, XKB_KEY_Q,   quit,           										{0} },
	{ ALT, XKB_KEY_Left,      chvt,           										{.ui = (3)}  },
	{ ALT, XKB_KEY_Right,     chvt,           										{.ui = (2)}  },
	// { ALT,                    XKB_KEY_comma,      focusmon,       {.i = WLR_DIRECTION_LEFT} },
	// { ALT,                    XKB_KEY_period,     focusmon,       {.i = WLR_DIRECTION_RIGHT} },
	WMKEYS(          XKB_KEY_1, XKB_KEY_exclam,                     0),
	WMKEYS(          XKB_KEY_2, XKB_KEY_at,                         1),
	WMKEYS(          XKB_KEY_3, XKB_KEY_numbersign,                 2),
	WMKEYS(          XKB_KEY_4, XKB_KEY_dollar,                     3),
	WMKEYS(          XKB_KEY_5, XKB_KEY_percent,                    4),
	WMKEYS(          XKB_KEY_6, XKB_KEY_asciicircum,                5),
	WMKEYS(          XKB_KEY_7, XKB_KEY_ampersand,                  6),
	WMKEYS(          XKB_KEY_8, XKB_KEY_asterisk,                   7),
	WMKEYS(          XKB_KEY_9, XKB_KEY_parenleft,                  8),

	// TAGKEYS(          XKB_KEY_1, XKB_KEY_exclam,                     0),
	// TAGKEYS(          XKB_KEY_2, XKB_KEY_at,                         1),
	// TAGKEYS(          XKB_KEY_3, XKB_KEY_numbersign,                 2),
	// TAGKEYS(          XKB_KEY_4, XKB_KEY_dollar,                     3),
	// TAGKEYS(          XKB_KEY_5, XKB_KEY_percent,                    4),
	// TAGKEYS(          XKB_KEY_6, XKB_KEY_asciicircum,                5),
	// TAGKEYS(          XKB_KEY_7, XKB_KEY_ampersand,                  6),
	// TAGKEYS(          XKB_KEY_8, XKB_KEY_asterisk,                   7),
	// TAGKEYS(          XKB_KEY_9, XKB_KEY_parenleft,                  8),

	/* Ctrl-Alt-Backspace and Ctrl-Alt-Fx used to be handled by X server */
	// { CTRL|ALT,XKB_KEY_Terminate_Server, quit, {0} },
	/* Ctrl-Alt-Fx is used to switch to another VT, if you don't know what a VT is
	 * do not remove them.
	 */
#define CHVT(n) { WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,XKB_KEY_XF86Switch_VT_##n, chvt, {.ui = (n)} }
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6),
	CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12)
};

static const Button buttons[] = {
	{ ALT | CTRL, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	// { ALT, BTN_MIDDLE, togglefloating, {0} },
	{ ALT | CTRL | SHIFT, BTN_LEFT,  moveresize,     {.ui = CurResize} },
};
