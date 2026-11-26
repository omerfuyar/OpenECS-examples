// The tally plugin's count and level, in C: each change goes into the history "tally_c" (OpenECS-std DESIGN 34), so Ctrl+Z and Ctrl+Y undo and redo
// them in the panel, and the History panel lists them. history's header, which the build writes from history's functions, gives them as C functions;
// the undo and redo of a record are C functions too, which get the data the record keeps, as they have no closure.

#include "history.h" // history's functions
#include "ui.h"      // ui's functions and macros; it includes OpenECS.h

#include <stdio.h>

/// @brief This plugin, for its log.
static ECSPlugin PLUGIN = nullptr;

/// @brief ui's functions, and what the macros describe into.
static Ui UI_PLUGIN;

/// @brief history's functions.
static HistoryFunctions HISTORY;

/// @brief The plugin's history, for its panel; a tool with documents would open one for each.
static void *TALLY_HISTORY = nullptr;

#define COUNT(array) (sizeof(array) / sizeof((array)[0]))

/// @brief The elements the test clicks, by id; their rectangles are saved, so the test finds them.
static const char *const IDS[] = {"add", "forget", "level"};

/// @brief The panel's state; the example has one panel, so the history's C functions find it here.
typedef struct Tally
{
    ECSPanel panel;
    i64 count;
    f64 level;
} Tally;

static Tally TALLY;

static SHUResult TallyCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)savedState;
    (void)version;

    TALLY = (Tally){.panel = panel, .level = 0.5};
    *retState = &TALLY;

    // Ctrl+Z and Ctrl+Y in this panel act on the plugin's history
    HISTORY.use(panel, TALLY_HISTORY);
    return SHUResult_Ok;
}

// a record's undo and redo get its data: the amount that was added
static void AddUndo(const ECSValue *data)
{
    TALLY.count -= ECSValue_GetInteger(data, 0);
    ECSPanel_Redraw(TALLY.panel);
}

static void AddRedo(const ECSValue *data)
{
    TALLY.count += ECSValue_GetInteger(data, 0);
    ECSPanel_Redraw(TALLY.panel);
}

/// @brief Adds to the count, and records how to take it back and make it again; the tag names what the record changes, for drop.
static SHUResult Add(i64 amount)
{
    ECSValue *tags = nullptr;
    ECSValue *data = nullptr;
    ECSValue *tag = nullptr;
    SHUResult result = ECSValue_Create(&tags);

    if (result == SHUResult_Ok)
    {
        result = ECSValue_Create(&data);
    }

    if (result == SHUResult_Ok)
    {
        ECSValue_SetTable(tags);
        result = ECSValue_AddListItem(tags, &tag);
    }

    if (result == SHUResult_Ok)
    {
        result = ECSValue_SetString(tag, "count");
    }

    if (result == SHUResult_Ok)
    {
        char label[32];
        snprintf(label, sizeof(label), "Add %lld", (long long)amount);
        ECSValue_SetInteger(data, amount);
        TALLY.count += amount;
        HISTORY.push(TALLY_HISTORY, label, "", tags, AddUndo, AddRedo, data);
    }

    ECSValue_Destroy(&data);
    ECSValue_Destroy(&tags);
    return result;
}

// the level's change gives the value to set: the new one now and at a redo, the old one at an undo
static void ApplyLevel(const ECSValue *value, const ECSValue *data)
{
    (void)data;
    TALLY.level = ECSValue_GetNumber(value, TALLY.level);
    ECSPanel_Redraw(TALLY.panel);
}

/// @brief Records a change of the level from the slider; the merge key joins the steps of a drag into one record.
static SHUResult ChangeLevel(f64 level)
{
    ECSValue *old = nullptr;
    ECSValue *new = nullptr;
    SHUResult result = ECSValue_Create(&old);

    if (result == SHUResult_Ok)
    {
        result = ECSValue_Create(&new);
    }

    if (result == SHUResult_Ok)
    {
        ECSValue_SetNumber(old, TALLY.level);
        ECSValue_SetNumber(new, level);
        HISTORY.change(TALLY_HISTORY, "Level", "level", old, new, ApplyLevel, nullptr);
    }

    ECSValue_Destroy(&new);
    ECSValue_Destroy(&old);
    return result;
}

static void TallyView(void *data, ECSSurface *surface)
{
    (void)surface;
    Tally *state = data;
    char text[64];
    snprintf(text, sizeof(text), "Count %lld, level %.2f", (long long)state->count, state->level);

    UI_COLUMN(.style = &UI_PLUGIN.styles.view, .gap = 8)
    {
        UI_TEXT(text, .id = "count", .style = &UI_PLUGIN.styles.title);

        UI_ROW(.gap = 8)
        {
            if (UI_BUTTON("Add one", .id = "add") && Add(1) != SHUResult_Ok)
            {
                ECS_LogWarn(PLUGIN, "Cannot record the change.");
            }

            // the counts' records go, as when what they changed was replaced from outside; C cannot raise an error, so the Lua plugin's Break,
            // whose undo fails, has no twin here
            if (UI_BUTTON("Forget the counts", .id = "forget"))
            {
                HISTORY.drop(TALLY_HISTORY, "count");
            }
        }

        // the slider writes the dragged level into its own copy, and the change sets the panel's through ApplyLevel
        f64 level = state->level;

        if (UI_SLIDER(&level, .id = "level") && level != state->level && ChangeLevel(level) != SHUResult_Ok)
        {
            ECS_LogWarn(PLUGIN, "Cannot record the change.");
        }
    }
}

// not read back; the test reads the panel's values, its history, and where its elements are, in layout units, here
static SHUResult TallySaveState(void *data, ECSValue *retSavedState)
{
    static const char *const NAMES[] = {"x", "y", "width", "height"};
    Tally *state = data;
    ECSValue *field = nullptr;
    ECSValue_SetTable(retSavedState);

    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "count", &field));
    ECSValue_SetInteger(field, state->count);
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "level", &field));
    ECSValue_SetNumber(field, state->level);
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "history", &field));
    SHU_ReturnResult(ECSValue_Copy(field, HISTORY.state(TALLY_HISTORY)));

    ECSValue *rects = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "rects", &rects));
    ECSValue_SetTable(rects);

    for (usz i = 0; i < COUNT(IDS); i++)
    {
        const ECSValue *rect = UI_PLUGIN.functions.rect(state->panel, IDS[i]);
        ECSValue *saved = nullptr;

        if (ECSValue_GetType(rect) != ECSValueType_Table)
        {
            continue;
        }

        SHU_ReturnResult(ECSValue_SetTableField(rects, IDS[i], &saved));
        ECSValue_SetTable(saved);

        for (usz j = 0; j < COUNT(NAMES); j++)
        {
            SHU_ReturnResult(ECSValue_SetTableField(saved, NAMES[j], &field));
            ECSValue_SetNumber(field, ECSValue_GetNumber(ECSValue_GetTableField(rect, NAMES[j]), 0.0));
        }
    }

    return SHUResult_Ok;
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    PLUGIN = plugin;

    // both look up their plugin's functions, which the manifest's dependencies make sure exist
    SHU_ReturnResult(Ui_Init(&UI_PLUGIN, plugin));
    SHU_ReturnResult(HistoryFunctions_Get(plugin, &HISTORY));
    TALLY_HISTORY = HISTORY.open("tally_c");
    // the tool's default history: Ctrl+Z and Ctrl+Y act on it in a panel that keeps none, and when no panel has the focus
    HISTORY.useDefault(TALLY_HISTORY);

    // history.changed is emitted at each change of a history, so the panel shows its count and level after an undo from the History panel too
    static const char *const REDRAW_ON[] = {"history.changed"};

    const UiPanelTypeDesc tally = {
        .type =
            {
                .name = "panel",
                .title = "Tally in C",
                .redrawOn = REDRAW_ON,
                .redrawOnCount = COUNT(REDRAW_ON),
                .Create = TallyCreate,
                .SaveState = TallySaveState,
            },
        .View = TallyView,
    };

    return ECSPanelType_Register(plugin, Ui_PanelType(&UI_PLUGIN, &tally));
}
