// A panel in C that hears the log: the core emits each line logged, by any plugin or the core, as the event ecs.logged.
// Its panels draw again whenever the plugin's own event heard_c.poked is emitted, without a list of them.

#include "OpenECS.h"

#include <string.h>

static ECSPlugin PLUGIN = nullptr;

static i64 HEARD = 0;  // this plugin's own warnings that the event brought
static i64 ECHOED = 0; // the lines that the handler logged itself, which the event leaves out
static i64 DRAWN = 0;  // how often a panel drew, which heard_c.poked makes it do again

// ecs.logged's value is a table: time, level ("debug", "info", "warn" or "error"), plugin ("ecs" for the core) and message
static void Logged(void *data, const char *name, const ECSValue *value)
{
    (void)data;
    (void)name;

    const char *level = ECSValue_GetString(ECSValue_GetTableField(value, "level"), "");
    const char *plugin = ECSValue_GetString(ECSValue_GetTableField(value, "plugin"), "");
    const char *message = ECSValue_GetString(ECSValue_GetTableField(value, "message"), "");
    const char *time = ECSValue_GetString(ECSValue_GetTableField(value, "time"), "");

    if (strcmp(plugin, "heard_c") != 0)
    {
        return;
    }

    if (strcmp(message, "A line the handler logs.") == 0)
    {
        ECHOED++;
        return;
    }

    if (strcmp(level, "warn") == 0 && strcmp(message, "A greeting warns.") == 0 && time[0] != '\0')
    {
        HEARD++;
        // a line logged while a handler of ecs.logged runs goes to the log, but not to the event, so a handler that logs does not hear itself
        ECS_LogWarn(PLUGIN, "A line the handler logs.");
    }
}

static SHUResult PanelCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)panel;
    (void)savedState;
    (void)version;

    ECS_LogWarn(PLUGIN, "A greeting warns.");
    *retState = nullptr;
    return SHUResult_Ok;
}

static void PanelDestroy(void *state)
{
    (void)state;
}

static SHUResult PanelSaveState(void *state, ECSValue *retSavedState)
{
    (void)state;
    ECSValue_SetTable(retSavedState);

    ECSValue *field = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "heard", &field));
    ECSValue_SetInteger(field, HEARD);
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "echoed", &field));
    ECSValue_SetInteger(field, ECHOED);
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "drawn", &field));
    ECSValue_SetInteger(field, DRAWN);
    return SHUResult_Ok;
}

static void PanelDraw(void *state, ECSSurface *surface, f64 seconds)
{
    (void)state;
    (void)seconds;
    DRAWN++;
    ECSSurface_Fill(surface, 0, 0, surface->width, surface->height, 0xFF434C5E);
}

static void Poke(void)
{
    // the panels hear nothing of it themselves: their type's redrawOn names the event, so the core draws them again
    if (ECSEvent_Emit(PLUGIN, "heard_c.poked", nullptr))
    {
        ECS_LogWarn(PLUGIN, "Cannot emit heard_c.poked.");
    }
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    PLUGIN = plugin;

    // the core's events need no dependency; the subscription lasts as long as the plugin
    ECSSubscription subscription = nullptr;
    SHU_ReturnResult(ECSEvent_Subscribe(plugin, &subscription, "ecs.logged", Logged, nullptr));

    // the events whose every emission draws each panel of the type again; an event is found by its name when it is emitted, so it may be
    // declared after the type, as heard_c.poked is below, and a name that nothing declares draws nothing
    static const char *const REDRAW_ON[] = {"heard_c.poked", "nobody.declares"};

    const ECSPanelTypeDesc heard = {
        .name = "panel",
        .title = "Heard in C",
        .redrawOn = REDRAW_ON,
        .redrawOnCount = sizeof(REDRAW_ON) / sizeof(*REDRAW_ON),
        .Create = PanelCreate,
        .Destroy = PanelDestroy,
        .SaveState = PanelSaveState,
        .Draw = PanelDraw,
    };

    SHU_ReturnResult(ECSPanelType_Register(plugin, &heard));
    SHU_ReturnResult(ECSEvent_Declare(plugin, "poked", "Asks every Heard in C panel to draw again"));
    return ECSService_RegisterFunction(plugin, "poke", (ECSFunction)Poke, "void()", "Draw every Heard in C panel again");
}
