// A panel that draws with the GPU, in C, with SDL's GPU API itself; the Lua plugin lights draws the same with the gpu standard plugin.
// A pixels panel writes its pixels on the CPU, and the core uploads them; a GPU panel draws into a texture on the GPU device that every OS window
// shows, so it moves to another window without being made again. This one clears its texture, copies four tiles into the middle, and moves a light
// along the bottom, with no shaders.

#include "OpenECS.h"

#include "SDL3/SDL.h" // a native plugin calls SDL itself, with the executable's copy

/// @brief The background, and the colours of the four tiles, 0xAARRGGBB.
#define LIGHTS_BACKGROUND 0xFF1B2A4A
static const u32 LIGHTS_TILES[4] = {0xFFBF616A, 0xFFA3BE8C, 0xFFEBCB8B, 0xFF5E81AC};

static struct
{
    ECSPlugin plugin;
    SDL_GPUDevice *device; // OpenECS's GPU device, which the panel's texture is on
} LIGHTS = {0};

/// @brief A panel's state: the texture of its tiles, and where the light is.
typedef struct Lights
{
    SDL_GPUTexture *tiles; // two by two pixels, one tile each
    f64 seconds;           // how long the panel has drawn, which moves the light
} Lights;

/// @brief Makes the texture of the tiles and uploads their colours: a transfer buffer takes the pixels, and a copy pass moves them to the texture.
static SDL_GPUTexture *LightsMakeTiles(SDL_GPUDevice *device)
{
    // ARGB8888 in native byte order is B8G8R8A8_UNORM, the format of a panel's texture too
    const SDL_GPUTextureCreateInfo info = {
        .type = SDL_GPU_TEXTURETYPE_2D,
        .format = SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM,
        .usage = SDL_GPU_TEXTUREUSAGE_SAMPLER,
        .width = 2,
        .height = 2,
        .layer_count_or_depth = 1,
        .num_levels = 1,
    };
    SDL_GPUTexture *tiles = SDL_CreateGPUTexture(device, &info);
    const SDL_GPUTransferBufferCreateInfo transferInfo = {.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD, .size = sizeof(LIGHTS_TILES)};
    SDL_GPUTransferBuffer *transfer = tiles == nullptr ? nullptr : SDL_CreateGPUTransferBuffer(device, &transferInfo);
    void *mapped = transfer == nullptr ? nullptr : SDL_MapGPUTransferBuffer(device, transfer, false);
    SDL_GPUCommandBuffer *commands = mapped == nullptr ? nullptr : SDL_AcquireGPUCommandBuffer(device);

    if (commands == nullptr)
    {
        ECS_LogError(LIGHTS.plugin, "Cannot upload the tiles: %s", SDL_GetError());
        SDL_ReleaseGPUTransferBuffer(device, transfer);
        SDL_ReleaseGPUTexture(device, tiles);
        return nullptr;
    }

    SDL_memcpy(mapped, LIGHTS_TILES, sizeof(LIGHTS_TILES));
    SDL_UnmapGPUTransferBuffer(device, transfer);

    SDL_GPUCopyPass *copy = SDL_BeginGPUCopyPass(commands);
    const SDL_GPUTextureTransferInfo source = {.transfer_buffer = transfer};
    const SDL_GPUTextureRegion destination = {.texture = tiles, .w = 2, .h = 2, .d = 1};
    SDL_UploadToGPUTexture(copy, &source, &destination, false);
    SDL_EndGPUCopyPass(copy);
    SDL_SubmitGPUCommandBuffer(commands);

    // the device keeps the buffer until the upload is done
    SDL_ReleaseGPUTransferBuffer(device, transfer);
    return tiles;
}

static SHUResult LightsCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)panel;
    (void)savedState;
    (void)version;

    // without a GPU renderer there is no device, and the panel shows the error
    SDL_GPUDevice *device = LIGHTS.device;
    Lights *lights = device == nullptr ? nullptr : SDL_calloc(1, sizeof(Lights));

    if (lights == nullptr || (lights->tiles = LightsMakeTiles(device)) == nullptr)
    {
        SDL_free(lights);
        return device == nullptr ? SHUResult_ErrNotFound : SHUResult_ErrInternal;
    }

    *retState = lights;
    return SHUResult_Ok;
}

static void LightsDestroy(void *state)
{
    Lights *lights = state;
    SDL_ReleaseGPUTexture(LIGHTS.device, lights->tiles);
    SDL_free(lights);
}

/// @brief Copies one tile, or a part of the tiles, into a rectangle of the panel's texture, scaled with the nearest pixel.
static void LightsBlit(SDL_GPUCommandBuffer *commands, const Lights *lights, ECSSurface *surface, SDL_FRect source, SDL_FRect destination)
{
    const SDL_GPUBlitInfo blit = {
        .source = {.texture = lights->tiles, .x = (Uint32)source.x, .y = (Uint32)source.y, .w = (Uint32)source.w, .h = (Uint32)source.h},
        .destination = {.texture = surface->texture, .x = (Uint32)destination.x, .y = (Uint32)destination.y, .w = (Uint32)destination.w, .h = (Uint32)destination.h},
        .load_op = SDL_GPU_LOADOP_LOAD, // what the texture holds stays around the rectangle
        .filter = SDL_GPU_FILTER_NEAREST,
    };
    SDL_BlitGPUTexture(commands, &blit);
}

// the surface's texture is the panel's, on the device that ECSGpu_GetDevice gives; the panel draws with a command buffer of its own and submits it,
// and the core shows the texture after
static void LightsDraw(void *state, ECSSurface *surface, f64 seconds)
{
    Lights *lights = state;
    lights->seconds += seconds;
    SDL_GPUCommandBuffer *commands = SDL_AcquireGPUCommandBuffer(LIGHTS.device);

    if (commands == nullptr)
    {
        ECS_LogError(LIGHTS.plugin, "Cannot draw: %s", SDL_GetError());
        return;
    }

    // a render pass that does nothing but clear fills the texture with the background
    const SDL_GPUColorTargetInfo target = {
        .texture = surface->texture,
        .clear_color = {((LIGHTS_BACKGROUND >> 16) & 0xFF) / 255.0f, ((LIGHTS_BACKGROUND >> 8) & 0xFF) / 255.0f, (LIGHTS_BACKGROUND & 0xFF) / 255.0f, 1.0f},
        .load_op = SDL_GPU_LOADOP_CLEAR,
        .store_op = SDL_GPU_STOREOP_STORE,
    };
    SDL_EndGPURenderPass(SDL_BeginGPURenderPass(commands, &target, 1, nullptr));

    // the four tiles fill a square in the middle, half as tall as the panel
    f32 side = SDL_floorf((f32)SDL_min(surface->width, surface->height) / 2.0f);
    SDL_FRect square = {SDL_floorf(((f32)surface->width - side) / 2.0f), SDL_floorf(((f32)surface->height - side) / 2.0f), side, side};
    LightsBlit(commands, lights, surface, (SDL_FRect){0, 0, 2, 2}, square);

    // the light, the yellow tile, goes along the bottom and back every four seconds
    f32 size = SDL_floorf(side / 8.0f) + 1.0f;
    f64 phase = SDL_fmod(lights->seconds / 4.0, 1.0);
    f32 across = (f32)(phase < 0.5 ? phase * 2.0 : 2.0 - phase * 2.0);
    SDL_FRect light = {SDL_floorf(across * ((f32)surface->width - size)), (f32)surface->height - size * 2.0f, size, size};
    LightsBlit(commands, lights, surface, (SDL_FRect){0, 1, 1, 1}, light);

    SDL_SubmitGPUCommandBuffer(commands);
}

SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    LIGHTS.plugin = plugin;

    // OpenECS owns the device, and destroys it after the plugins
    LIGHTS.device = ECSGpu_GetDevice();

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
