//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_secure_storage_windows/flutter_secure_storage_windows_plugin.h>
#include <infusion_ffi/infusion_ffi_plugin.h>
#include <webcrypto/webcrypto_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterSecureStorageWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterSecureStorageWindowsPlugin"));
  InfusionFfiPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("InfusionFfiPlugin"));
  WebcryptoPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WebcryptoPlugin"));
}
