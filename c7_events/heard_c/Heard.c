// A panel in C that hears the log: the core emits each line logged, by any plugin or the core, as the event ecs.logged.

#include "OpenECS.h"

#include <string.h>

static ECSPlugin PLUGIN = nullptr;

static i64 HEARD = 0;  // this plugin's own warnings that the event brought
static i64 ECHOED = 0; // the lines that the handler logged itself, which the event leaves out

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
    return SHUResult_Ok;
}

static void PanelDraw(void *state, ECSSurface *surface, f64 seconds)
{
    (void)state;
    (void)seconds;
    ECSSurface_Fill(surface, 0, 0, surface->width, surface->height, 0xFF434C5E);
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    PLUGIN = plugin;

    // the core's events need no dependency; the subscription lasts as long as the plugin
    ECSSubscription subscription = nullptr;
    SHU_ReturnResult(ECSEvent_Subscribe(plugin, &subscription, "ecs.logged", Logged, nullptr));

    const ECSPanelTypeDesc heard = {
        .name = "panel",
        .title = "Heard in C",
        .Create = PanelCreate,
        .Destroy = PanelDestroy,
        .SaveState = PanelSaveState,
        .Draw = PanelDraw,
    };

    return ECSPanelType_Register(plugin, &heard);
}
