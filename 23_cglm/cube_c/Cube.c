// The cube of the cube plugin, in C. cglm's header, which the build writes from cglm's functions (OpenECS DESIGN 10.10), ends with cglm's own
// header, so C calls cglm's inline functions, such as glm_mat4_mul, and calls nothing to make its matrices; the same functions answer Lua's calls
// to the cglm plugin. draw's header gives draw's functions, which draw the edges.

#include "cglm.h" // the cglm plugin's functions, and cglm itself
#include "draw.h" // draw's functions; it includes OpenECS.h

#include <stdlib.h>

/// @brief draw's functions, which DrawFunctions_Get looks up.
static DrawFunctions DRAW;

/// @brief The edges of the cube, as pairs of corners from 0, the same as the Lua plugin's.
static const u32 EDGES[24] = {0, 1, 2, 3, 4, 5, 6, 7, 0, 2, 1, 3, 4, 6, 5, 7, 0, 4, 1, 5, 2, 6, 3, 7};

typedef struct Cube
{
    ECSPanel panel;
    f32 turn;
    f32 scale; // the surface's at the last draw, as events give positions in its pixels
    bool dragging;
    f32 dragX; // where the drag was at its last event, in layout units
} Cube;

/// @brief A corner of the cube, from 0: each bit of its number picks -1 or 1 on one axis.
static void CubeCorner(usz i, vec3 retCorner)
{
    retCorner[0] = (i & 1) ? 1.0f : -1.0f;
    retCorner[1] = (i & 2) ? 1.0f : -1.0f;
    retCorner[2] = (i & 4) ? 1.0f : -1.0f;
}

/// @brief The matrix that takes a corner to the view: the cube turns around the vertical axis and leans, then the camera and the perspective see it.
static void CubeMatrix(f32 turn, mat4 retMatrix)
{
    vec3 up = {0.0f, 1.0f, 0.0f}, across = {1.0f, 0.0f, 0.0f};
    mat4 lean, model, camera, projection;

    glm_rotate_make(model, turn, up);
    glm_rotate_make(lean, 0.4f, across);
    glm_mat4_mul(model, lean, model);
    glm_lookat((vec3){0.0f, 2.0f, 5.0f}, (vec3){0.0f, 0.0f, 0.0f}, up, camera);
    glm_perspective(glm_rad(45.0f), 1.0f, 0.1f, 50.0f, projection);

    glm_mat4_mul(camera, model, retMatrix);
    glm_mat4_mul(projection, retMatrix, retMatrix);
}

/// @brief A corner in a view from 0 to 1 each way, from its bottom left, as glm_project gives it.
static void CubeProject(mat4 matrix, usz i, vec3 retPoint)
{
    vec3 corner;
    CubeCorner(i, corner);
    glm_project(corner, matrix, (vec4){0.0f, 0.0f, 1.0f, 1.0f}, retPoint);
}

static SHUResult CubeCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)savedState;
    (void)version;

    Cube *cube = calloc(1, sizeof(Cube));

    if (cube == nullptr)
    {
        return SHUResult_ErrAllocation;
    }

    *cube = (Cube){.panel = panel, .turn = 0.6f, .scale = 1.0f};
    *retState = cube;
    return SHUResult_Ok;
}

static void CubeDestroy(void *state)
{
    free(state);
}

static void CubeDraw(void *state, ECSSurface *surface, f64 seconds)
{
    (void)seconds;
    Cube *cube = state;
    cube->scale = surface->scale;

    f32 width = (f32)surface->width / surface->scale, height = (f32)surface->height / surface->scale;
    ECSColor background = 0, accent = 0;
    ECSColor_Parse("#101418", &background);
    ECSColor_Parse("accent", &accent);
    DRAW.fill(surface, 0.0f, 0.0f, width, height, background);

    // the square view in the middle of the panel, whose y goes down
    f32 side = width < height ? width : height;
    f32 left = (width - side) / 2.0f, top = (height - side) / 2.0f;
    mat4 matrix;
    f32 points[16];
    CubeMatrix(cube->turn, matrix);

    for (usz i = 0; i < 8; i++)
    {
        vec3 point;
        CubeProject(matrix, i, point);
        points[i * 2] = left + point[0] * side;
        points[i * 2 + 1] = top + (1.0f - point[1]) * side;
    }

    DRAW.lines(surface, cs(points, sizeof(points)), cs((void *)EDGES, sizeof(EDGES)), 2.0f, accent);
}

// a drag across turns the cube
static void CubeEvent(void *state, const ECSPanelEvent *event)
{
    Cube *cube = state;
    f32 x = event->pointer.x / cube->scale;

    if (event->type == ECSPanelEventType_PointerDown && event->pointer.button == 1)
    {
        cube->dragging = true;
        cube->dragX = x;
    }
    else if (event->type == ECSPanelEventType_PointerUp)
    {
        cube->dragging = false;
    }
    else if (event->type == ECSPanelEventType_PointerMove && cube->dragging)
    {
        cube->turn += (x - cube->dragX) * 0.01f;
        cube->dragX = x;
        ECSPanel_Redraw(cube->panel);
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

// the turn, and where the last corner is in the view, as the Lua plugin saves them, so the test compares the two
static SHUResult CubeSaveState(void *state, ECSValue *retSavedState)
{
    Cube *cube = state;
    mat4 matrix;
    vec3 corner;
    CubeMatrix(cube->turn, matrix);
    CubeProject(matrix, 7, corner);

    ECSValue_SetTable(retSavedState);
    SHU_ReturnResult(SetNumber(retSavedState, "turn", cube->turn));

    ECSValue *saved = nullptr;
    SHU_ReturnResult(ECSValue_SetTableField(retSavedState, "corner", &saved));
    ECSValue_SetTable(saved);
    SHU_ReturnResult(SetNumber(saved, "x", corner[0]));
    SHU_ReturnResult(SetNumber(saved, "y", corner[1]));
    return SHUResult_Ok;
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    // the manifest's dependency on draw makes sure its functions exist
    SHU_ReturnResult(DrawFunctions_Get(plugin, &DRAW));

    const ECSPanelTypeDesc cube = {
        .name = "panel",
        .title = "Cube in C",
        .Create = CubeCreate,
        .Destroy = CubeDestroy,
        .Draw = CubeDraw,
        .Event = CubeEvent,
        .SaveState = CubeSaveState,
    };

    return ECSPanelType_Register(plugin, &cube);
}
