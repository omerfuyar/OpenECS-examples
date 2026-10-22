// The controls of the button plugin, in C: the same elements, ids and state as the Lua plugin in ../button, so both behave the same. ui's header,
// which the build writes from ui's functions (OpenECS DESIGN 10.10), has macros that describe the elements in the manner of Clay's CLAY: a container's
// block holds its children, and each draw describes them anew. ui builds them with the same functions as for Lua. C gives ui no functions: an element
// with an id keeps what happened to it, and its macro takes that at the next draw.

#include "ui.h" // ui's functions and macros; it includes OpenECS.h

#include <stdio.h>
#include <stdlib.h>

/// @brief ui's functions, and what the macros describe into.
static Ui UI;

#define COUNT(array) (sizeof(array) / sizeof((array)[0]))

static const char *const FRUITS[] = {"Apple", "Banana", "Cherry", nullptr};
static const char *const SIZES[] = {"S", "M", "L", nullptr};
static const char *const TABS[] = {"Options", "About", "Table", nullptr};
static const char *const ITEMS[] = {"First item", "Second item", "Third item"};

/// @brief The Table tab's columns and rows; the panel sorts the rows, and the table shows them in its order.
static const UiColumn COLUMNS[] = {{.id = "name", .title = "Fruit"}, {.id = "price", .title = "Price"}, {.id = "stock", .title = "In stock"}, {0}};

typedef struct FruitRow
{
    const char *name;
    f64 price;
    f64 stock;
    const char *priceText;
    const char *stockText;
} FruitRow;

static const FruitRow FRUIT_ROWS[] = {{"Cherry", 4.5, 12, "4.5", "12"}, {"Apple", 1.2, 40, "1.2", "40"}, {"Banana", 0.8, 25, "0.8", "25"}};

/// @brief The elements the test clicks, by id; their rectangles are saved, so the test finds them.
static const char *const IDS[] = {"button", "tab", "sound", "volume", "size", "fruit", "count", "item:2", "name", "note", "tree:src",
                                  "tree:lib", "table:header", "table:1", "table:2", "table:title:name", "table:title:price"};

static const char *const NOTE = "Tab gives the keys to the next control and Shift+Tab to the one before. Return or Space presses the control that has them, "
                                "Left and Right change a selector or a slider, and Escape takes the keys away. A field takes typing as soon as it has the keys. "
                                "In a field, Home and End move the cursor to its start and end, Shift with them selects, and Ctrl+C, Ctrl+X and Ctrl+V copy, cut and paste.";

/// @brief A panel's state: the value of each control, and the surface's scale at the last draw, for the rectangles.
typedef struct Controls
{
    ECSPanel panel;
    f32 scale;
    i32 clicks;
    bool sound;
    bool dark;
    f64 volume;
    i32 size;  // the chosen size's index in SIZES
    i32 fruit; // the chosen fruit's index in FRUITS
    f64 count;
    i32 tab;      // the chosen tab's index in TABS
    i32 selected; // the list's chosen item, from 1
    char name[64];
    const char *node; // the tree's chosen node's id
    bool srcOpen;     // the tree's open nodes
    bool libOpen;
    const char *sort; // the id of the column the rows are sorted by
    bool ascending;
    i32 row; // the table's chosen row, from 1, or 0 for none
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

    *controls = (Controls){.panel = panel, .scale = 1.0f, .dark = true, .volume = 0.5, .size = 1, .count = 3, .selected = 1, .node = "readme", .sort = "name", .ascending = true};
    *retState = controls;
    return SHUResult_Ok;
}

static void ControlsDestroy(void *state)
{
    Controls *controls = state;
    UI.functions.forget(controls->panel);
    free(controls);
}

/// @brief Whether a row comes before another in the order the panel sorts them: by its sort column, up or down.
static bool RowBefore(const Controls *controls, const FruitRow *row, const FruitRow *other)
{
    int order = strcmp(controls->sort, "name") == 0    ? strcmp(row->name, other->name)
                : strcmp(controls->sort, "price") == 0 ? (row->price > other->price) - (row->price < other->price)
                                                        : (row->stock > other->stock) - (row->stock < other->stock);
    return controls->ascending ? order < 0 : order > 0;
}

/// @brief The rows of the Table tab, in the order the panel sorts them.
static void SortRows(const Controls *controls, FruitRow *retRows)
{
    for (usz i = 0; i < COUNT(FRUIT_ROWS); i++)
    {
        usz at = i;

        while (at > 0 && RowBefore(controls, &FRUIT_ROWS[i], &retRows[at - 1]))
        {
            retRows[at] = retRows[at - 1];
            at--;
        }

        retRows[at] = FRUIT_ROWS[i];
    }
}

// a table lines its cells up below its columns' titles; a click on a title sorts by that column, and a second one reverses the order
static void DescribeTable(Controls *controls)
{
    const char *column = UI_SORTED("table");

    for (usz i = 0; column != nullptr && COLUMNS[i].id != nullptr; i++)
    {
        if (strcmp(column, COLUMNS[i].id) == 0)
        {
            controls->ascending = strcmp(COLUMNS[i].id, controls->sort) != 0 || !controls->ascending;
            controls->sort = COLUMNS[i].id;
            controls->row = 0;
        }
    }

    FruitRow rows[COUNT(FRUIT_ROWS)];
    const char *cells[COUNT(FRUIT_ROWS) * 3];
    SortRows(controls, rows);

    for (usz i = 0; i < COUNT(FRUIT_ROWS); i++)
    {
        cells[i * 3] = rows[i].name;
        cells[i * 3 + 1] = rows[i].priceText;
        cells[i * 3 + 2] = rows[i].stockText;
    }

    UI_TABLE(&controls->row, COLUMNS, cells, COUNT(FRUIT_ROWS), .id = "table", .height = 110, .grow = UI_FIXED, .stretch = true, .border = "tabShown",
             .sort = controls->sort, .ascending = controls->ascending);
}

// a tree shows its open nodes' children below them; the panel keeps which nodes are open, and the chosen one
static void DescribeTree(Controls *controls)
{
    const UiTreeNode lib[] = {{.id = "util", .label = "util.c"}, {0}};
    const UiTreeNode src[] = {{.id = "main", .label = "main.c"}, {.id = "lib", .label = "lib", .children = lib, .open = &controls->libOpen}, {0}};
    const UiTreeNode nodes[] = {{.id = "src", .label = "src", .children = src, .open = &controls->srcOpen}, {.id = "readme", .label = "README.md"}, {0}};

    UI_COLUMN(.gap = 8)
    {
        UI_TEXT("The controls of ui, each changing the panel's state.", .color = "textDim");
        UI_TREE(&controls->node, nodes, .id = "tree", .height = 110, .grow = UI_FIXED, .border = "tabShown");
    }
}

static void DescribeOptions(Controls *controls)
{
    UI_GROUP(.title = "Options", .gap = 8)
    {
        UI_TOGGLE(&controls->sound, .id = "sound", .label = "Sound");
        UI_TOGGLE(&controls->dark, .id = "dark", .label = "Dark", .look = "switch");

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

        UI_ROW(.gap = 8)
        {
            UI_TEXT("Fruit");
            UI_DROPDOWN(&controls->fruit, FRUITS, .id = "fruit");
        }

        // a number field takes a number from min to max: Return gives what is typed, and Up and Down change it by step
        UI_ROW(.gap = 8)
        {
            UI_TEXT("Count");
            UI_NUMBER(&controls->count, .id = "count", .min = 0, .max = 10, .step = 1, .grow = 1);
        }
    }
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

            // UI_BUTTON gives whether the button was clicked since the last draw; a tooltip shows when the pointer rests on its element
            if (UI_BUTTON("Click me", .id = "button", .tooltip = "Counts the clicks in the panel's title"))
            {
                char title[64];
                snprintf(title, sizeof(title), "Controls in C (%d)", ++controls->clicks);
                ECSPanel_SetTitle(controls->panel, title);
            }

            UI_SEPARATOR();

            // tabs choose what shows below them; the panel keeps the chosen one and describes only its elements
            UI_TABS(&controls->tab, TABS, .id = "tab");

            if (strcmp(TABS[controls->tab], "Table") == 0)
            {
                DescribeTable(controls);
            }
            else if (strcmp(TABS[controls->tab], "About") == 0)
            {
                DescribeTree(controls);
            }
            else
            {
                DescribeOptions(controls);
            }

            UI_LIST(&controls->selected, .id = "list", .height = 90, .grow = UI_FIXED, .border = "tabShown")
            {
                for (usz i = 0; i < COUNT(ITEMS); i++)
                {
                    char id[16];
                    snprintf(id, sizeof(id), "item:%zu", i + 1);
                    UI_TEXT(ITEMS[i], .id = id);
                }
            }

            // a field keeps what is typed while it has the keys; Left, Right, Home and End move its cursor, Shift with them selects, and Ctrl+C, Ctrl+X and Ctrl+V copy, cut and paste
            UI_ROW(.gap = 8)
            {
                UI_TEXT("Name");
                UI_FIELD(controls->name, sizeof(controls->name), .id = "name", .grow = 1);
            }

            // text with wrap = true breaks into lines at the width of its column
            UI_TEXT(NOTE, .id = "note", .wrap = true, .color = "textDim");
        }
    }
}

// the panel's events go to ui, which calls the callbacks of the elements they reach; Up and Down choose a list's or the tree's next item and the one
// before, and Right and Left open and close the tree's chosen node
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

/// @brief Sets a field of a table to a text; nullptr leaves it nil.
static SHUResult SetString(ECSValue *table, const char *name, const char *text)
{
    ECSValue *field = nullptr;

    if (text == nullptr)
    {
        return SHUResult_Ok;
    }

    SHU_ReturnResult(ECSValue_SetTableField(table, name, &field));
    return ECSValue_SetString(field, text);
}

/// @brief Sets a field of a table to a bool.
static SHUResult SetBool(ECSValue *table, const char *name, bool value)
{
    ECSValue *field = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(table, name, &field));
    ECSValue_SetBool(field, value);
    return SHUResult_Ok;
}

/// @brief Saves the rectangles of the elements the test clicks, in the panel's surface pixels; ui.rect gives nothing for an element that is not
/// shown, such as one on another tab.
static SHUResult SaveRects(const Controls *controls, ECSValue *retRects)
{
    static const char *const NAMES[] = {"x", "y", "width", "height"};
    ECSValue_SetTable(retRects);

    for (usz i = 0; i < COUNT(IDS); i++)
    {
        const ECSValue *rect = UI.functions.rect(controls->panel, IDS[i]);
        ECSValue *saved = nullptr;

        if (ECSValue_GetType(rect) != ECSValueType_Table)
        {
            continue;
        }

        SHU_ReturnResult(ECSValue_SetTableField(retRects, IDS[i], &saved));
        ECSValue_SetTable(saved);

        for (usz j = 0; j < COUNT(NAMES); j++)
        {
            SHU_ReturnResult(SetNumber(saved, NAMES[j], ECSValue_GetNumber(ECSValue_GetTableField(rect, NAMES[j]), 0.0) * controls->scale));
        }
    }

    return SHUResult_Ok;
}

// the values and the rectangles are saved, so the test can read them
static SHUResult ControlsSaveState(void *state, ECSValue *retSavedState)
{
    Controls *controls = state;
    ECSValue_SetTable(retSavedState);
    SHU_ReturnResult(SetNumber(retSavedState, "clicks", controls->clicks));
    SHU_ReturnResult(SetBool(retSavedState, "sound", controls->sound));
    SHU_ReturnResult(SetNumber(retSavedState, "volume", controls->volume));
    SHU_ReturnResult(SetString(retSavedState, "size", SIZES[controls->size]));
    SHU_ReturnResult(SetString(retSavedState, "fruit", FRUITS[controls->fruit]));
    SHU_ReturnResult(SetNumber(retSavedState, "count", controls->count));
    SHU_ReturnResult(SetString(retSavedState, "tab", TABS[controls->tab]));
    SHU_ReturnResult(SetString(retSavedState, "tip", ECSValue_GetString(UI.functions.tooltip(controls->panel), nullptr)));
    SHU_ReturnResult(SetNumber(retSavedState, "selected", controls->selected));
    SHU_ReturnResult(SetString(retSavedState, "name", controls->name));
    SHU_ReturnResult(SetString(retSavedState, "node", controls->node));
    SHU_ReturnResult(SetString(retSavedState, "sort", controls->sort));
    SHU_ReturnResult(SetBool(retSavedState, "ascending", controls->ascending));

    ECSValue *open = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "open", &open));
    ECSValue_SetTable(open);

    if (controls->srcOpen)
    {
        SHU_ReturnResult(SetBool(open, "src", true));
    }

    if (controls->libOpen)
    {
        SHU_ReturnResult(SetBool(open, "lib", true));
    }

    if (controls->row > 0)
    {
        SHU_ReturnResult(SetNumber(retSavedState, "row", controls->row));
    }

    if (strcmp(TABS[controls->tab], "Table") == 0)
    {
        FruitRow rows[COUNT(FRUIT_ROWS)];
        SortRows(controls, rows);
        SHU_ReturnResult(SetString(retSavedState, "first", rows[0].name));
    }

    ECSValue *rects = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "rects", &rects));
    return SaveRects(controls, rects);
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
