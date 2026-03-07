#include <napi/native_api.h>
#include <hilog/log.h>

constexpr int DOMAIN = 0xFF00;
constexpr const char* TAG = "HarmonyProxy";

static napi_value Test(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LOG_APP, "HarmonyProxy Native Module Loaded");

    napi_value returnValue;
    napi_get_boolean(env, true, &returnValue);
    return returnValue;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "test", nullptr, Test, nullptr, nullptr, nullptr, napi_default, nullptr },
    };

    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) {
    napi_register_module(&demoModule);
}
