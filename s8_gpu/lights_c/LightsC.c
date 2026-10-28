// A panel that draws with the GPU, in C: the gpu standard plugin draws into a GPU surface, as the Lua plugin lights does, here through gpu.h, the header
// that OpenECS --definitions writes for gpu. A pixels panel writes its pixels on the CPU, and the core uploads them; a GPU panel draws into a texture on
// the GPU device that every OS window shows, so it moves to another window without being made again. This one draws four tiles on a background, and a
// light that goes along the bottom.

#include "gpu.h" // gpu's functions; it includes OpenECS.h

#include <math.h>
#include <stdlib.h>

/// @brief The background, the colours of the four tiles and the light's, 0xAARRGGBB.
#define LIGHTS_BACKGROUND 0xFF1B2A4A
#define LIGHTS_LIGHT 0xFFEBCB8B
static const ECSColor LIGHTS_TILES[4] = {0xFFBF616A, 0xFFA3BE8C, 0xFFEBCB8B, 0xFF5E81AC};

static struct
{
    ECSPlugin plugin;
    GpuFunctions gpu;
} LIGHTS = {0};

/// @brief A panel's state: how long it has drawn, which moves the light.
typedef struct Lights
{
    f64 seconds;
} Lights;

static SHUResult LightsCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)panel;
    (void)savedState;
    (void)version;

    Lights *state = calloc(1, sizeof(Lights));

    if (state == nullptr)
    {
        return SHUResult_ErrAllocation;
    }

    *retState = state;
    return SHUResult_Ok;
}

static void LightsDestroy(void *data)
{
    free(data);
}

// gpu draws into the surface as draw does into pixels, in layout units; what it draws reaches the GPU once the Draw returns (ECSSurface_OnDrawn)
static void LightsDraw(void *data, ECSSurface *surface, f64 seconds)
{
    Lights *state = data;
    state->seconds += seconds;

    f32 width = (f32)surface->width / surface->scale;
    f32 height = (f32)surface->height / surface->scale;
    LIGHTS.gpu.clear(surface, LIGHTS_BACKGROUND);

    // the four tiles fill a square in the middle, half as tall as the panel
    f32 side = floorf(fminf(width, height) / 2.0f);
    f32 left = floorf((width - side) / 2.0f);
    f32 top = floorf((height - side) / 2.0f);
    f32 half = side / 2.0f;

    for (int row = 0; row < 2; row++)
    {
        for (int column = 0; column < 2; column++)
        {
            LIGHTS.gpu.fill(surface, left + (f32)column * half, top + (f32)row * half, half, half, LIGHTS_TILES[row * 2 + column]);
        }
    }

    // the light goes along the bottom and back every four seconds
    f32 size = floorf(side / 8.0f) + 1.0f;
    f64 phase = fmod(state->seconds / 4.0, 1.0);
    f32 across = (f32)(phase < 0.5 ? phase * 2.0 : 2.0 - phase * 2.0);
    LIGHTS.gpu.fill(surface, floorf(across * (width - size)), height - size * 2.0f, size, size, LIGHTS_LIGHT);
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    LIGHTS.plugin = plugin;

    // the manifest depends on gpu, so its functions are there to look up
    SHU_ReturnResult(GpuFunctions_Get(plugin, &LIGHTS.gpu));

    const ECSPanelTypeDesc panel = {
        .name = "panel",
        .title = "Lights in C",
        .surface = ECSSurfaceType_Gpu, // the panel draws into a GPU texture instead of pixels
        .continuous = true,            // the light moves, so the panel draws every frame
        .Create = LightsCreate,
        .Destroy = LightsDestroy,
        .Draw = LightsDraw,
    };

    return ECSPanelType_Register(plugin, &panel);
}
