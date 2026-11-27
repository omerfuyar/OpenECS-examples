// The controls of the button plugin, in C: the same elements, ids and state as the Lua plugin in ../button, so both behave the same. ui's header,
// which the build writes from ui's functions (OpenECS DESIGN 10.10), has macros that describe the elements in the manner of Clay's CLAY: a container's
// block holds its children, and each draw describes them anew. ui builds them with the same functions as for Lua. An element with an id keeps what
// happened to it, and its macro takes that at the next draw; where ui needs an answer at once, as a drag does, the props take C functions.

#include "ui.h" // ui's functions and macros; it includes OpenECS.h

#include <stdio.h>
#include <stdlib.h>

/// @brief ui's functions, and what the macros describe into.
static Ui UI_PLUGIN;

// a style is a UiProps of look props, kept in a variable so elements share it, and .style points to it; UI_PLUGIN.styles holds ui's own
static const UiProps LABELED = {.gap = 8};

#define COUNT(array) (sizeof(array) / sizeof((array)[0]))

static const char *const FRUITS[] = {"Apple", "Banana", "Cherry", nullptr};
// more choices than a window holds, so the dropdown's popup scrolls
static const char *const ITEMS[] = {"Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6", "Item 7", "Item 8", "Item 9", "Item 10", "Item 11", "Item 12", "Item 13", "Item 14", "Item 15", "Item 16", "Item 17", "Item 18", "Item 19", "Item 20", "Item 21", "Item 22", "Item 23", "Item 24", "Item 25", "Item 26", "Item 27", "Item 28", "Item 29", "Item 30", "Item 31", "Item 32", "Item 33", "Item 34", "Item 35", "Item 36", "Item 37", "Item 38", "Item 39", "Item 40", nullptr};
static const char *const SIZES[] = {"S", "M", "L", nullptr};
static const char *const TABS[] = {"Options", "About", "Table", nullptr};
#define ITEM_COUNT 40
static const char *const TAGS[] = {"Lua", "C", "SDL", "Clay", "libffi", "stb"};
static const char *const TAG_IDS[] = {"tag:1", "tag:2", "tag:3", "tag:4", "tag:5", "tag:6"};

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
static const char *const IDS[] = {"button", "tab", "sound", "volume", "size", "fruit", "item", "count", "item:2", "name", "note", "beside", "tree:src",
                                  "tree:main", "tree:lib", "tree:f100", "tree:readme:star", "tree:readme:lock", "icon:eye", "icon:eyeClosed", "icon:lock", "icon:lockOpen", "lockButton", "table:header", "table:1", "table:2", "table:title:name", "table:title:price", "about",
                                  "tint", "colors:heading", "tag:1", "tag:2", "tag:6", "file", "list", "cut", "lines", "cutLines", "cutSpans"};

static const char *const NOTE = "Tab gives the keys to the next control and Shift+Tab to the one before. Return or Space presses the control that has them, "
                                "Left and Right change a selector or a slider, and Escape takes the keys away. A field takes typing as soon as it has the keys. "
                                "In a field, Home and End move the cursor to its start and end, Shift with them selects, and Ctrl+C, Ctrl+X and Ctrl+V copy, cut and paste.";

/// @brief A panel's state: the value of each control, and the surface's scale at the last draw, for the rectangles.
typedef struct Controls
{
    ECSPanel panel;
    f32 scale;
    bool gpu; // the surface is a GPU one, as the setting ui.gpu puts ui's panels on the GPU
    i32 clicks;
    i32 untaken; // the keys that reached the panel's own Event, which ui did not take
    bool sound;
    bool dark;
    f64 volume;
    f64 kept;  // the volume that the slider's drag ended on
    i32 size;  // the chosen size's number in SIZES, from 1
    i32 fruit; // the chosen fruit's number in FRUITS, from 1
    i32 item;  // the chosen item's number in ITEMS, from 1
    f64 count;
    i32 tab;      // the chosen tab's number in TABS, from 1
    i32 selected; // the list's chosen item, from 1
    char name[64];
    char file[256];
    const char *node; // the tree's chosen node's id
    bool srcOpen;     // the tree's open nodes
    bool libOpen;
    bool starred;     // whether README.md's mark is on
    bool locked;      // whether README.md's padlock is locked
    const char *sort; // the id of the column the rows are sorted by
    bool ascending;
    i32 row;       // the table's chosen row, from 1, or 0 for none
    char link[96]; // the link last clicked in the About tab's text
    char tint[10]; // a colour, "#RRGGBB"
    bool colors;   // whether the Colour section is open
    struct
    {
        char node[16]; // the node dropped on the tree
        char where[8]; // where it landed: before, after or into
        char on[16];   // the node it landed on
    } dropped;
    char menuNode[16]; // the node a right click gave to the tree's onMenu
    char renamed[16];  // the node whose menu's Rename was clicked
} Controls;

static SHUResult ControlsCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)savedState;
    (void)version;

    Controls *state = calloc(1, sizeof(Controls));

    if (state == nullptr)
    {
        return SHUResult_ErrAllocation;
    }

    *state = (Controls){.panel = panel, .scale = 1.0f, .dark = true, .volume = 0.5, .kept = 0.5, .size = 2, .fruit = 1, .item = 1, .tab = 1, .count = 3, .selected = 1, .node = "readme", .sort = "name", .ascending = true, .tint = "#3366CC", .colors = true};
    *retState = state;

    // the panel takes the tree's nodes that are dragged onto it, as data of the core's drag and drop
    const char *const drops[] = {"example.node"};
    return ECSPanel_AcceptDrops(panel, drops, COUNT(drops));
}

// the panel's own Event gets only the events that ui did not take, such as a key while no element has the keys; it counts those keys
static void ControlsEvent(void *data, const ECSPanelEvent *event)
{
    Controls *state = data;

    if (event->type == ECSPanelEventType_KeyDown)
    {
        state->untaken++;
    }
}

// ui forgets the panel before its Destroy runs
static void ControlsDestroy(void *data)
{
    free(data);
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
        usz position = i;

        while (position > 0 && RowBefore(controls, &FRUIT_ROWS[i], &retRows[position - 1]))
        {
            retRows[position] = retRows[position - 1];
            position--;
        }

        retRows[position] = FRUIT_ROWS[i];
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

    UI_TABLE(&controls->row, COLUMNS, cells, COUNT(FRUIT_ROWS), .id = "table", .height = 110, .grow = UI_FIXED, .stretch = true, .border = "frame",
             .onSort = true, .sort = controls->sort, .ascending = controls->ascending ? UI_TRUE : UI_FALSE);
}

/// @brief The parent of a node of the tree, or nullptr for src and README.md, at the top; lib holds every file but main.c.
static const char *ParentOf(const char *id)
{
    if (strcmp(id, "main") == 0 || strcmp(id, "lib") == 0)
    {
        return "src";
    }

    return strcmp(id, "src") == 0 || strcmp(id, "readme") == 0 ? nullptr : "lib";
}

/// @brief Whether a node is the one with an id, or one of its parents.
static bool Holds(const char *node, const char *id)
{
    for (; id != nullptr; id = ParentOf(id))
    {
        if (strcmp(id, node) == 0)
        {
            return true;
        }
    }

    return false;
}

// a press on a node and a move of the pointer drag what onDrag gives, as data of the core's drag and drop: the node's id
static bool TreeDrag(void *user, const ECSValue *item, const char **retType, ECSValue *retValue)
{
    (void)user;
    *retType = "example.node";
    return ECSValue_SetString(retValue, ECSValue_GetString(item, "")) == SHUResult_Ok;
}

// while a node is dragged, the tree asks where it may land, with what onDrop would get: a node may not land on itself or inside itself, so false
// refuses it, and the tree marks nothing there; a file holds nothing, so a node dropped into one goes after it
static bool TreeDragOver(void *user, UiDrop *drop)
{
    (void)user;
    const char *id = ECSValue_GetString(drop->item, nullptr);

    if (id != nullptr && Holds(ECSValue_GetString(drop->value, ""), id))
    {
        return false;
    }

    if (drop->where == UI_INTO && strcmp(id, "src") != 0 && strcmp(id, "lib") != 0)
    {
        drop->where = UI_AFTER;
    }

    return true;
}

// a node dropped on the tree gives the node it landed on, and where: before it, into it, or after it, by where on its row
static void TreeDrop(void *user, const UiDrop *drop)
{
    Controls *controls = user;
    static const char *const WHERE[] = {"", "before", "after", "into"};
    snprintf(controls->dropped.node, sizeof(controls->dropped.node), "%s", ECSValue_GetString(drop->value, ""));
    snprintf(controls->dropped.where, sizeof(controls->dropped.where), "%s", WHERE[drop->where]);
    snprintf(controls->dropped.on, sizeof(controls->dropped.on), "%s", ECSValue_GetString(drop->item, ""));
}

static void TreeRename(void *user)
{
    Controls *controls = user;
    snprintf(controls->renamed, sizeof(controls->renamed), "%s", controls->menuNode);
}

// a right click on a node chooses it, unless it is chosen, and gives its id and the place, where the tree opens a menu about the node
static void TreeMenu(void *user, const ECSValue *item, f64 x, f64 y)
{
    Controls *controls = user;
    snprintf(controls->menuNode, sizeof(controls->menuNode), "%s", ECSValue_GetString(item, ""));
    const UiMenuEntry entries[] = {{.label = "Rename", .onClick = TreeRename, .user = controls}, {0}};
    Ui_Menu(&UI_PLUGIN, controls->panel, x, y, entries);
}

// a tree shows its open nodes' children below them; the panel keeps which nodes are open, and the chosen one
static void DescribeTree(Controls *controls)
{
    // lib holds a hundred files, so its tree is long when it is open; the tree builds only the rows in view and near it
    static char ids[100][16];
    static char labels[100][24];
    static UiTreeNode lib[101];

    if (lib[0].id == nullptr)
    {
        lib[0] = (UiTreeNode){.id = "util", .label = "util.c"};

        for (int i = 2; i <= 100; i++)
        {
            snprintf(ids[i - 1], sizeof(ids[i - 1]), "f%d", i);
            snprintf(labels[i - 1], sizeof(labels[i - 1]), "file%d.c", i);
            lib[i - 1] = (UiTreeNode){.id = ids[i - 1], .label = labels[i - 1]};
        }
    }

    const UiTreeNode src[] = {{.id = "main", .label = "main.c"}, {.id = "lib", .label = "lib", .children = lib, .open = &controls->libOpen}, {0}};
    // a node's marks are short labels at the end of its row, on or off; README.md has a star, and a padlock that shows locked or open,
    // which UI_TREE turns in the panel's bools
    const UiTreeMark marks[] = {{.id = "star", .label = "Star", .on = &controls->starred, .tooltip = "A click stars the file, or takes the star off"},
                                {.id = "lock", .spans = UI_LABEL({.icon = controls->locked ? "lock" : "lockOpen"}), .on = &controls->locked, .tooltip = "A click locks the file, or unlocks it"},
                                {0}};
    const UiTreeNode nodes[] = {{.id = "src", .label = "src", .children = src, .open = &controls->srcOpen}, {.id = "readme", .label = "README.md", .marks = marks}, {0}};

    UI_COLUMN(.gap = 8)
    {
        // a text of spans mixes styles; UI_SPANS gives the link of a span that was clicked
        const UiSpan about[] = {{.text = "The controls of "}, {.text = "ui", .bold = true}, {.text = ", each changing the panel's state: "}, {.text = "ui's design", .link = "https://github.com/omerfuyar/OpenECS-std/blob/dev/DESIGN.md"}};
        const char *link = UI_SPANS(about, COUNT(about), .id = "about", .color = "textDim");

        if (link != nullptr)
        {
            snprintf(controls->link, sizeof(controls->link), "%s", link);
        }

        // icons are small pictures drawn from shapes, a line of text high, in a colour
        UI_ROW(.gap = 8)
        {
            UI_ICON("eye", .id = "icon:eye", .tooltip = "Shown");
            UI_ICON("eyeClosed", .id = "icon:eyeClosed", .tooltip = "Hidden");
            UI_ICON("lock", .id = "icon:lock", .color = "accent", .tooltip = "Locked");
            UI_ICON("lockOpen", .id = "icon:lockOpen", .tooltip = "Open");

            // a label is a text, or spans of words and pictures, wherever one shows: a button's, a tree's node and mark, a section's title
            if (UI_BUTTON("lockButton", .spans = UI_LABEL({.icon = controls->locked ? "lock" : "lockOpen"}, {.text = controls->locked ? " Unlock" : " Lock"})))
            {
                controls->locked = !controls->locked;
            }
        }

        // C functions in the props give what ui asks at once, such as where a dragged node may land, and get what the user did, with the props'
        // user, the panel's state
        UI_TREE(&controls->node, nodes, .id = "tree", .height = 110, .grow = UI_FIXED, .border = "frame", .user = controls, .onDrag = TreeDrag,
                .onDragOver = TreeDragOver, .onDrop = TreeDrop, .onMenu = TreeMenu);

        // a row with wrap = true puts the children that do not fit the rest of a line on the next line, as a toolbar does in a narrow panel;
        // this one is in a narrow column, so its buttons take two lines
        UI_COLUMN(.width = 160)
        {
            UI_ROW(.wrap = true, .gap = 4)
            {
                for (usz i = 0; i < COUNT(TAGS); i++)
                {
                    (void)UI_BUTTON(TAGS[i], .id = TAG_IDS[i]);
                }
            }
        }

        // a text with maxLines wraps, and shows at most that many lines; the last one ends with an ellipsis when more follow, as a long
        // file's name does under its icon. Spans do the same
        UI_COLUMN(.width = 160)
        {
            UI_TEXT(NOTE, .id = "cut", .maxLines = 2);
            UI_TEXT("Lua\nLua", .id = "lines");
            UI_TEXT("Lua\nLua\nC", .id = "cutLines", .maxLines = 2);
            const UiSpan cutSpans[] = {{.text = "Lua\n"}, {.text = "Lua\nC"}};
            (void)UI_SPANS(cutSpans, COUNT(cutSpans), .id = "cutSpans", .maxLines = 2);
        }
    }
}

static void DescribeOptions(Controls *controls)
{
    UI_GROUP(.title = "Options", .gap = 8)
    {
        UI_TOGGLE(&controls->sound, .id = "sound", .label = "Sound");
        UI_TOGGLE(&controls->dark, .id = "dark", .label = "Dark", .look = "switch");

        UI_ROW(.style = &LABELED)
        {
            UI_TEXT("Volume");
            UI_SLIDER(&controls->volume, .id = "volume", .step = 0.1, .grow = 1);
            // UI_SUBMITTED tells when a drag of the slider ended, as a tool keeps one change for it
            if (UI_SUBMITTED("volume"))
            {
                controls->kept = controls->volume;
            }
        }

        UI_ROW(.style = &LABELED)
        {
            UI_TEXT("Size");
            UI_SELECTOR(&controls->size, SIZES, .id = "size");
        }

        UI_ROW(.style = &LABELED)
        {
            UI_TEXT("Fruit");
            UI_DROPDOWN(&controls->fruit, FRUITS, .id = "fruit");
        }

        UI_ROW(.style = &LABELED)
        {
            UI_TEXT("Item");
            UI_DROPDOWN(&controls->item, ITEMS, .id = "item");
        }

        // a number field takes a number from min to max: Return gives what is typed, and Up and Down change it by step
        UI_ROW(.style = &LABELED)
        {
            UI_TEXT("Count");
            UI_NUMBER(&controls->count, .id = "count", .min = 0, .max = 10, .step = 1, .grow = 1);
        }

        // a section's heading shows and hides what is below it, at a click, which UI_SECTION writes into the bool
        // a colour element is a swatch, which a click opens in a picker; UI_COLOR writes the colour a press in the picker ends on
        UI_SECTION(&controls->colors, "Colour", .id = "colors")
        {
            UI_ROW(.style = &LABELED)
            {
                UI_TEXT("Tint");
                UI_COLOR(controls->tint, sizeof(controls->tint), .id = "tint");
            }
        }
    }
}

// each draw describes every element, which ui shows; a macro that takes a pointer writes into it what the user changed since the last draw
static void ControlsView(void *data, ECSSurface *surface)
{
    Controls *state = data;
    state->scale = surface->scale;
    state->gpu = surface->type == ECSSurfaceType_Gpu;
    char clicked[64];
    snprintf(clicked, sizeof(clicked), "Clicked %d times", state->clicks);

    UI_COLUMN(.style = &UI_PLUGIN.styles.view)
    {
        UI_TEXT(clicked, .style = &UI_PLUGIN.styles.title);

        // UI_BUTTON gives whether the button was clicked since the last draw; a tooltip shows when the pointer rests on its element
        if (UI_BUTTON("Click me", .id = "button", .tooltip = "Counts the clicks in the panel's title"))
        {
            char title[64];
            snprintf(title, sizeof(title), "Controls in C (%d)", ++state->clicks);
            ECSPanel_SetTitle(state->panel, title);
        }

        UI_SEPARATOR();

        // tabs choose what shows below them; the panel keeps the chosen one and describes only its elements
        UI_TABS(&state->tab, TABS, .id = "tab");

        if (strcmp(TABS[state->tab - 1], "Table") == 0)
        {
            DescribeTable(state);
        }
        else if (strcmp(TABS[state->tab - 1], "About") == 0)
        {
            DescribeTree(state);
        }
        else
        {
            DescribeOptions(state);
        }

        // a long list describes only the items in view and near it, which ui's range gives; the list gets count, its number of items, and first
        i32 first = 0;
        i32 last = 0;
        UI_PLUGIN.functions.range(state->panel, "list", ITEM_COUNT, &first, &last);

        UI_LIST(&state->selected, .id = "list", .count = ITEM_COUNT, .first = first, .height = 90, .grow = UI_FIXED, .border = "frame")
        {
            for (i32 i = first; i <= last; i++)
            {
                char id[16];
                char text[16];
                snprintf(id, sizeof(id), "item:%d", (int)i);
                snprintf(text, sizeof(text), "Item %d", (int)i);
                UI_TEXT(text, .id = id);
            }
        }

        // a path is a field with a button that opens the system's file dialog; UI_PATH writes the typed or chosen path into its buffer
        UI_ROW(.style = &LABELED)
        {
            UI_TEXT("File");
            UI_PATH(state->file, sizeof(state->file), .id = "file", .grow = 1, .pattern = "lua");
        }

        // a field keeps what is typed while it has the keys; Left, Right, Home and End move its cursor, Shift with them selects, and Ctrl+C, Ctrl+X and Ctrl+V copy, cut and paste
        UI_ROW(.style = &LABELED)
        {
            UI_TEXT("Name");
            UI_FIELD(state->name, sizeof(state->name), .id = "name", .grow = 1);
        }

        // text with wrap = true breaks into lines at the width of its column
        UI_TEXT(NOTE, .id = "note", .style = &UI_PLUGIN.styles.note, .wrap = true);

        // in a row, wrapped text and columns share what the other children leave, and a growing column's text breaks at the width it grows to
        UI_ROW(.gap = 8)
        {
            UI_TEXT("Keys", .wrap = true);

            UI_COLUMN(.grow = 1)
            {
                UI_TEXT(NOTE, .id = "beside", .style = &UI_PLUGIN.styles.note, .wrap = true);
            }
        }
    }
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
        const ECSValue *rect = UI_PLUGIN.functions.rect(controls->panel, IDS[i]);
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
static SHUResult ControlsSaveState(void *data, ECSValue *retSavedState)
{
    Controls *state = data;
    ECSValue_SetTable(retSavedState);
    SHU_ReturnResult(SetString(retSavedState, "surface", state->gpu ? "gpu" : "pixels"));
    SHU_ReturnResult(SetNumber(retSavedState, "clicks", state->clicks));
    SHU_ReturnResult(SetNumber(retSavedState, "untaken", state->untaken));
    SHU_ReturnResult(SetBool(retSavedState, "sound", state->sound));
    SHU_ReturnResult(SetNumber(retSavedState, "volume", state->volume));
    SHU_ReturnResult(SetNumber(retSavedState, "kept", state->kept));
    SHU_ReturnResult(SetString(retSavedState, "size", SIZES[state->size - 1]));
    SHU_ReturnResult(SetString(retSavedState, "fruit", FRUITS[state->fruit - 1]));
    SHU_ReturnResult(SetString(retSavedState, "item", ITEMS[state->item - 1]));
    SHU_ReturnResult(SetNumber(retSavedState, "count", state->count));
    SHU_ReturnResult(SetString(retSavedState, "tab", TABS[state->tab - 1]));
    SHU_ReturnResult(SetString(retSavedState, "tip", ECSValue_GetString(UI_PLUGIN.functions.tooltip(state->panel), nullptr)));
    SHU_ReturnResult(SetNumber(retSavedState, "selected", state->selected));
    SHU_ReturnResult(SetString(retSavedState, "name", state->name));
    SHU_ReturnResult(SetString(retSavedState, "file", state->file));
    SHU_ReturnResult(SetString(retSavedState, "link", state->link[0] != '\0' ? state->link : nullptr));
    SHU_ReturnResult(SetString(retSavedState, "tint", state->tint));
    SHU_ReturnResult(SetBool(retSavedState, "colors", state->colors));
    SHU_ReturnResult(SetString(retSavedState, "node", state->node));
    SHU_ReturnResult(SetBool(retSavedState, "starred", state->starred));
    SHU_ReturnResult(SetBool(retSavedState, "locked", state->locked));
    SHU_ReturnResult(SetString(retSavedState, "sort", state->sort));
    SHU_ReturnResult(SetBool(retSavedState, "ascending", state->ascending));

    SHU_ReturnResult(SetString(retSavedState, "menuNode", state->menuNode[0] != '\0' ? state->menuNode : nullptr));
    SHU_ReturnResult(SetString(retSavedState, "renamed", state->renamed[0] != '\0' ? state->renamed : nullptr));

    if (state->dropped.node[0] != '\0')
    {
        ECSValue *dropped = nullptr;
        SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "dropped", &dropped));
        ECSValue_SetTable(dropped);
        SHU_ReturnResult(SetString(dropped, "node", state->dropped.node));
        SHU_ReturnResult(SetString(dropped, "where", state->dropped.where));
        SHU_ReturnResult(SetString(dropped, "on", state->dropped.on));
    }

    ECSValue *open = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "open", &open));
    ECSValue_SetTable(open);

    if (state->srcOpen)
    {
        SHU_ReturnResult(SetBool(open, "src", true));
    }

    if (state->libOpen)
    {
        SHU_ReturnResult(SetBool(open, "lib", true));
    }

    if (state->row > 0)
    {
        SHU_ReturnResult(SetNumber(retSavedState, "row", state->row));
    }

    if (strcmp(TABS[state->tab - 1], "Table") == 0)
    {
        FruitRow rows[COUNT(FRUIT_ROWS)];
        SortRows(state, rows);
        SHU_ReturnResult(SetString(retSavedState, "first", rows[0].name));
    }

    ECSValue *rects = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "rects", &rects));
    return SaveRects(state, rects);
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    // Ui_Init looks up ui's functions, which the manifest's dependency on ui makes sure exist
    SHU_ReturnResult(Ui_Init(&UI_PLUGIN, plugin));

    // Ui_PanelType completes the type with ui's part: its Draw shows what View describes, and its events go to ui, which calls the callbacks of the
    // elements they reach; Up and Down choose a list's or the tree's next item and the one before, and Right and Left open and close the tree's chosen
    // node
    const UiPanelTypeDesc controls = {
        .type =
            {
                .name = "panel",
                .title = "Controls in C",
                .Create = ControlsCreate,
                .Destroy = ControlsDestroy,
                .Event = ControlsEvent,
                .SaveState = ControlsSaveState,
            },
        .View = ControlsView,
    };

    return ECSPanelType_Register(plugin, Ui_PanelType(&UI_PLUGIN, &controls));
}
