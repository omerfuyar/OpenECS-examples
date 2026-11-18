// Named counters, in C. Other plugins, in any language, call its functions by name and signature.
// A function registered by name is a service: keys, menus, presets and other plugins can run it.

#include "OpenECS.h"

#include <string.h>

#define COUNTER_MAX 16
#define COUNTER_NAME_SIZE 32
#define COUNTER_WATCHERS 8

/// @brief A function that hears each change of a counter: void(string name, int value).
typedef void (*CounterWatchFunction)(const char *name, i32 value);

static struct
{
    ECSPlugin plugin;
    char names[COUNTER_MAX][COUNTER_NAME_SIZE];
    i64 values[COUNTER_MAX];
    usz count;
    CounterWatchFunction watchers[COUNTER_WATCHERS];
    usz watcherCount;
} COUNTERS = {0};

/// @brief Finds a counter.
/// @return The counter, or nullptr if there is none of the name.
static i64 *CounterFind(const char *name)
{
    for (usz i = 0; i < COUNTERS.count; i++)
    {
        if (strcmp(COUNTERS.names[i], name) == 0)
        {
            return &COUNTERS.values[i];
        }
    }

    return nullptr;
}

// the string is valid only during the call, so it is copied if kept
static i32 CounterAdd(const char *name, i32 amount, const char **retError)
{
    *retError = nullptr;

    // a misuse is the caller's mistake: ECS_Check reports it, fails the callback that made the call, and gives false, so the function returns at once
    if (!ECS_Check(COUNTERS.plugin, strlen(name) < COUNTER_NAME_SIZE, "A counter's name is shorter than %d bytes.", COUNTER_NAME_SIZE))
    {
        return 0;
    }

    i64 *value = CounterFind(name);

    // a failure is not the caller's mistake: ECS_Fail writes why into the out string error, which Lua gets as nil and why
    if (value == nullptr && COUNTERS.count == COUNTER_MAX)
    {
        ECS_Fail(COUNTERS.plugin, retError, "There is no room for the counter '%s'.", name);
        return 0;
    }

    if (value == nullptr)
    {
        strcpy(COUNTERS.names[COUNTERS.count], name);
        value = &COUNTERS.values[COUNTERS.count++];
    }

    *value += amount;

    for (usz i = 0; i < COUNTERS.watcherCount; i++)
    {
        COUNTERS.watchers[i](name, (i32)*value);
    }

    return (i32)*value;
}

static i32 CounterGet(const char *name)
{
    i64 *value = CounterFind(name);
    return value == nullptr ? 0 : (i32)*value;
}

// a callback of type "keep fn<...>" stays valid after the call, so the plugin can call it later; a plain "fn<...>" is valid only during the call
static bool CounterWatch(CounterWatchFunction watcher, const char **retError)
{
    *retError = nullptr;

    // a watcher that is not stored is released at once, as nothing calls it later
    if (COUNTERS.watcherCount == COUNTER_WATCHERS)
    {
        ECSService_ReleaseCallback((ECSFunction)watcher);
        ECS_Fail(COUNTERS.plugin, retError, "%d functions watch the counters already.", COUNTER_WATCHERS);
        return false;
    }

    COUNTERS.watchers[COUNTERS.watcherCount++] = watcher;
    return true;
}

// a kept callback is released once it is no longer called: one that a Lua function gave is freed then
static void CounterDestroy(void *data)
{
    (void)data;

    for (usz i = 0; i < COUNTERS.watcherCount; i++)
    {
        ECSService_ReleaseCallback((ECSFunction)COUNTERS.watchers[i]);
    }

    COUNTERS.watcherCount = 0;
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    COUNTERS.plugin = plugin;
    const ECSPluginDesc desc = {.Destroy = CounterDestroy};
    SHU_ReturnResult(ECSPlugin_Register(plugin, &desc));

    // the signature tells the core how to pass the arguments: the result's type, then each parameter's type and name
    // the function is cast to ECSFunction, the type of any function; the signature says its real type
    // a function that can fail says why in "out string error", its last parameter
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "add", (ECSFunction)CounterAdd, "int(string name, int amount, out string error)", "Adds to a named counter, and gives its new value"));
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "get", (ECSFunction)CounterGet, "int(string name)", "Gives a named counter's value"));
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "watch", (ECSFunction)CounterWatch, "bool(keep fn<void(string name, int value)> watcher, out string error)", "Calls a function with each change of a counter, until the program exits"));
    return SHUResult_Ok;
}
