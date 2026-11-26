// The watcher plugin in C: it watches a folder and the folders inside it with fs's recursive watch, and keeps each change it is told, by its path in
// the folder, as ../watcher does in Lua. fs's header gives its functions; the build writes it with the standard plugins' headers.

#include "OpenECS.h"
#include "fs.h"

#include <stdio.h>
#include <string.h>

#define WATCHER_MAX 1024
#define WATCHER_LINE 256

static struct
{
    ECSPlugin plugin;
    FsFunctions fs;
    void *watch;                          // the watch, or nullptr
    char root[WATCHER_LINE];              // the watched folder, ending with a slash
    char seen[WATCHER_MAX][WATCHER_LINE]; // the changes since the watch began, such as "a/b/note.txt:added"
    usz count;
} WATCHER = {0};

// the folder that a change comes with is the watched folder and the folder inside it, ending with a slash; an empty name is the folder itself, with
// "overflow" or "gone"
static void WatcherChanged(const char *folder, const char *name, const char *change)
{
    usz length = strlen(WATCHER.root);

    if (WATCHER.count < WATCHER_MAX)
    {
        snprintf(WATCHER.seen[WATCHER.count++], WATCHER_LINE, "%s%s:%s", strncmp(folder, WATCHER.root, length) == 0 ? folder + length : folder, name, change);
    }
}

static bool WatcherStart(const char *folder, const char **retError)
{
    *retError = nullptr;

    if (WATCHER.watch != nullptr)
    {
        WATCHER.fs.unwatch(WATCHER.watch);
        WATCHER.watch = nullptr;
    }

    WATCHER.count = 0;
    snprintf(WATCHER.root, sizeof(WATCHER.root), "%s", folder);

    // true: the folders inside are watched too, apart from those whose names start with a dot
    const char *error = nullptr;
    WATCHER.watch = WATCHER.fs.watch(folder, WatcherChanged, true, &error);

    if (WATCHER.watch == nullptr)
    {
        ECS_Fail(WATCHER.plugin, retError, "%s", error);
        return false;
    }

    return true;
}

static SHUResult WatcherSeen(i32 first, ECSValue *retSeen)
{
    ECSValue_SetTable(retSeen);

    for (usz i = first > 1 ? (usz)first - 1 : 0; i < WATCHER.count; i++)
    {
        ECSValue *item = nullptr;
        SHU_ReturnResult(ECSValue_AddListItem(retSeen, &item));
        SHU_ReturnResult(ECSValue_SetString(item, WATCHER.seen[i]));
    }

    return SHUResult_Ok;
}

static void WatcherGive(i32 first, ECSValue *retSeen)
{
    if (WatcherSeen(first, retSeen) != SHUResult_Ok)
    {
        ECSValue_SetNil(retSeen);
    }
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    WATCHER.plugin = plugin;
    const ECSPluginDesc desc = {0};
    SHU_ReturnResult(ECSPlugin_Register(plugin, &desc));
    SHU_ReturnResult(FsFunctions_Get(plugin, &WATCHER.fs));
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "start", (ECSFunction)WatcherStart, "bool(string folder, out string error)", "Watches a folder and the folders inside it, in place of the folder it watched"));
    SHU_ReturnResult(ECSService_RegisterFunction(plugin, "seen", (ECSFunction)WatcherGive, "void(int first, out value<string[]> seen)",
                                                 "Gives the changes since the watch began, from the first-th on, each the entry's path in the folder and the change, such as a/note.txt:added"));
    return SHUResult_Ok;
}
