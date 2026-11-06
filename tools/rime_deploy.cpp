// Headless Rime deployment using the librime C API.
// Used by tools/deploy.ps1 because WeaselDeployer /deploy does not reliably
// rebuild schemas whose build cache is missing.  This talks to librime
// directly (no Weasel GUI, no installer dialog).
//
// Build:
//   cl /nologo /EHsc /std:c++17 /utf-8 /I tools /Fo:tools\ /Fe:tools\rime_deploy.exe tools\rime_deploy.cpp

#include <windows.h>
#include <cstdio>
#include <cstdlib>
#include <string>

#include "rime_api.h"

typedef RimeApi* (*RimeGetApiFn)(void);

static std::string user_data_dir() {
  const char* env = getenv("PUFF_RIME_USER_DIR");
  if (env && *env) {
    return env;
  }
  const char* appdata = getenv("APPDATA");
  return std::string(appdata ? appdata : ".") + "\\Rime";
}

int main() {
  std::string dll_path = "C:\\Program Files\\Rime\\weasel-0.17.4\\rime.dll";
  if (const char* env = getenv("PUFF_RIME_DLL")) {
    if (*env) dll_path = env;
  }
  std::string shared_dir = "C:\\Program Files\\Rime\\weasel-0.17.4\\data";
  if (const char* env = getenv("PUFF_RIME_SHARED_DATA")) {
    if (*env) shared_dir = env;
  }
  HMODULE dll = LoadLibraryExA(dll_path.c_str(), NULL, LOAD_WITH_ALTERED_SEARCH_PATH);
  if (!dll) {
    printf("LoadLibrary failed: %lu\n", GetLastError());
    return 2;
  }
  RimeGetApiFn get_api = (RimeGetApiFn)GetProcAddress(dll, "rime_get_api");
  if (!get_api) {
    printf("rime_get_api not found\n");
    FreeLibrary(dll);
    return 3;
  }
  RimeApi* api = get_api();
  if (!api || api->data_size <= 0) {
    printf("invalid RimeApi\n");
    FreeLibrary(dll);
    return 4;
  }

  std::string user_dir = user_data_dir();
  RimeTraits traits = {0};
  RIME_STRUCT_INIT(RimeTraits, traits);
  traits.shared_data_dir = shared_dir.c_str();
  traits.user_data_dir = user_dir.c_str();
  traits.distribution_name = "Weasel";
  traits.distribution_code_name = "weasel";
  traits.distribution_version = "0.17.4";
  traits.app_name = "rime.puffdeploy";
  traits.min_log_level = 0;

  api->setup(&traits);
  api->deployer_initialize(&traits);
  Bool ok = api->deploy();
  printf("deploy=%d\n", ok);
  api->deploy_config_file("weasel.yaml", "config_version");
  api->finalize();
  FreeLibrary(dll);
  return ok ? 0 : 1;
}
