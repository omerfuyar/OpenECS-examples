// The smallest native plugin: one panel type that fills itself with one colour. 1_hello does the same in Lua.

#include "OpenECS.h" // the only header a plugin includes; it declares everything the core gives plugins

/// @brief The plugin, which the functions that log need. The core gives it to ECSPlugin_Init.
static ECSPlugin PLUGIN = nullptr;

// the core calls it when a panel of the type opens; the state it gives back goes to the other functions
// this panel needs no state of its own, so it gives none
static SHUResult GreetingCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)panel;
    (void)savedState;
    (void)version;

    // ECS_LogDebug, ECS_LogInfo, ECS_LogWarn and ECS_LogError write at one level; ECS_Log takes the level
    ECS_LogInfo(PLUGIN, "A greeting opens.");
    *retState = nullptr;
    return SHUResult_Ok; // an error instead shows on the panel, in place of its drawing
}

// the core calls it when the panel closes
static void GreetingDestroy(void *state)
{
    (void)state;
    ECS_LogInfo(PLUGIN, "A greeting closes.");
}

// the core calls it only when the panel needs drawing; the surface is valid only during this call
// C may also write the surface's pixels directly: ARGB, one row every pitch bytes
static void GreetingDraw(void *state, ECSSurface *surface, f64 seconds)
{
    (void)state;
    (void)seconds;

    ECS_LogInfo(PLUGIN, "The greeting draws itself, %d by %d pixels.", surface->width, surface->height);
    // a colour is an ECSColor, 0xAARRGGBB; ECSColor_Parse reads one from a text such as "#5E81AC" or "accent"
    ECSSurface_Fill(surface, 0, 0, surface->width, surface->height, 0xFF5E81AC);
}

// the core calls it once, after it loads the library; register everything here, not later
SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    PLUGIN = plugin;
    ECS_LogInfo(plugin, "The plugin loads.");

    const ECSPanelTypeDesc greeting = {
        .name = "greeting", // the local name: the core names the type "hello_c.greeting"
        .title = "Greeting in C",
        .Create = GreetingCreate,
        .Destroy = GreetingDestroy,
        .Draw = GreetingDraw,
    };

    return ECSPanelType_Register(plugin, &greeting); // an error fails the plugin, and its panels show the error
}
