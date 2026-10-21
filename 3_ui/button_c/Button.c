// The controls of the button plugin, in C. ui's header, which the build writes from ui's functions (OpenECS DESIGN 10.10), has macros that describe
// the elements in the manner of Clay's CLAY: a container's block holds its children, and each draw describes them anew. ui builds them with the same
// functions as for Lua. C gives ui no functions: an element with an id keeps what happened to it, and its macro takes that at the next draw.

#include "ui.h" // ui's functions and macros; it includes OpenECS.h

#include <stdio.h>
#include <stdlib.h>

/// @brief ui's functions, and what the macros describe into.
static Ui UI;

static const char *const SIZES[] = {"S", "M", "L", nullptr};
static const char *const ITEMS[] = {"First item", "Second item", "Third item"};

/// @brief The elements the test clicks, by id; their rectangles are saved, so the test finds them.
static const char *const IDS[] = {"button", "sound", "volume", "size", "name", "item:2"};

typedef struct Controls
{
    ECSPanel panel;
    f32 scale; // the surface's at the last draw, for the rectangles
    i32 clicks;
    bool sound;
    f64 volume;
    i32 size; // the chosen size's index in SIZES
    char name[64];
    i32 selected; // the chosen item, from 1
} Controls;

static SHUResult ControlsCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)savedState;
    (void)version;

    Controls *controls = calloc(1, sizeof(Controls));

    if (controls == nullptr)
    {
        return SHUResult_ErrAllocation;
    }

    *controls = (Controls){.panel = panel, .scale = 1.0f, .volume = 0.5, .size = 1, .selected = 1};
    *retState = controls;
    return SHUResult_Ok;
}

static void ControlsDestroy(void *state)
{
    Controls *controls = state;
    UI.functions.forget(controls->panel);
    free(controls);
}

// each draw describes every element; a macro that takes a pointer writes into it what the user changed since the last draw
static void ControlsDraw(void *state, ECSSurface *surface, f64 seconds)
{
    (void)seconds;
    Controls *controls = state;
    controls->scale = surface->scale;
    char clicked[64];
    snprintf(clicked, sizeof(clicked), "Clicked %d times", controls->clicks);

    UI_SHOW(&UI, controls->panel, surface)
    {
        UI_COLUMN(.padding = 24, .gap = 12)
        {
            UI_TEXT(clicked, .size = 18);

            // UI_BUTTON gives whether the button was clicked since the last draw
            if (UI_BUTTON("Click me", .id = "button", .tooltip = "Counts the clicks in the panel's title"))
            {
                char title[64];
                snprintf(title, sizeof(title), "Controls in C (%d)", ++controls->clicks);
                ECSPanel_SetTitle(controls->panel, title);
            }

            UI_SEPARATOR();

            UI_GROUP(.title = "Options", .gap = 8)
            {
                UI_TOGGLE(&controls->sound, .id = "sound", .label = "Sound");

                UI_ROW(.gap = 8)
                {
                    UI_TEXT("Volume");
                    UI_SLIDER(&controls->volume, .id = "volume", .step = 0.1, .grow = 1);
                }

                UI_ROW(.gap = 8)
                {
                    UI_TEXT("Size");
                    UI_SELECTOR(&controls->size, SIZES, .id = "size");
                }
            }

            UI_LIST(&controls->selected, .id = "list", .height = 90, .grow = UI_FIXED, .border = "tabShown")
            {
                for (usz i = 0; i < sizeof(ITEMS) / sizeof(ITEMS[0]); i++)
                {
                    char id[16];
                    snprintf(id, sizeof(id), "item:%zu", i + 1);
                    UI_TEXT(ITEMS[i], .id = id);
                }
            }

            UI_ROW(.gap = 8)
            {
                UI_TEXT("Name");
                UI_FIELD(controls->name, sizeof(controls->name), .id = "name", .grow = 1);
            }
        }
    }
}

static void ControlsEvent(void *state, const ECSPanelEvent *event)
{
    Controls *controls = state;
    Ui_Event(&UI, controls->panel, event);
}

/// @brief Sets a field of a table to a number.
static SHUResult SetNumber(ECSValue *table, const char *name, f64 number)
{
    ECSValue *field = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(table, name, &field));
    ECSValue_SetNumber(field, number);
    return SHUResult_Ok;
}

// the values and the rectangles are saved, so the test can read them; ui.rect gives an element's rectangle in the last layout
static SHUResult ControlsSaveState(void *state, ECSValue *retSavedState)
{
    Controls *controls = state;
    ECSValue *field = nullptr;
    ECSValue_SetTable(retSavedState);
    SHU_ReturnResult(SetNumber(retSavedState, "clicks", controls->clicks));
    SHU_ReturnResult(SetNumber(retSavedState, "volume", controls->volume));
    SHU_ReturnResult(SetNumber(retSavedState, "selected", controls->selected));
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "sound", &field));
    ECSValue_SetBool(field, controls->sound);
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "size", &field));
    SHU_ReturnResult(ECSValue_SetString(field, SIZES[controls->size]));
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "name", &field));
    SHU_ReturnResult(ECSValue_SetString(field, controls->name));

    ECSValue *rects = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "rects", &rects));
    ECSValue_SetTable(rects);

    for (usz i = 0; i < sizeof(IDS) / sizeof(IDS[0]); i++)
    {
        const ECSValue *rect = UI.functions.rect(controls->panel, IDS[i]);

        if (ECSValue_GetType(rect) == ECSValueType_Table)
        {
            ECSValue *saved = nullptr;
            SHU_ReturnResult(ECSValue_SetTableField(rects, IDS[i], &saved));
            ECSValue_SetTable(saved);

            for (usz j = 0; j < 4; j++)
            {
                const char *names[] = {"x", "y", "width", "height"};
                SHU_ReturnResult(SetNumber(saved, names[j], ECSValue_GetNumber(ECSValue_GetTableField(rect, names[j]), 0.0) * controls->scale));
            }
        }
    }

    return SHUResult_Ok;
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    // Ui_Init looks up ui's functions, which the manifest's dependency on ui makes sure exist
    SHU_ReturnResult(Ui_Init(&UI, plugin));

    const ECSPanelTypeDesc controls = {
        .name = "panel",
        .title = "Controls in C",
        .Create = ControlsCreate,
        .Destroy = ControlsDestroy,
        .Draw = ControlsDraw,
        .Event = ControlsEvent,
        .SaveState = ControlsSaveState,
    };

    return ECSPanelType_Register(plugin, &controls);
}
