# 🍵 Tisane

![Pub Version](https://img.shields.io/pub/v/tisane)
![License](https://img.shields.io/github/license/dooapps/tisane)
![Build Status](https://img.shields.io/github/workflow/status/dooapps/tisane/Dart)
![Style](https://img.shields.io/badge/style-effective__dart-40c4ff.svg)

**Tisane** is a decentralized, offline-first integration layer designed for the next generation of Flutter applications. It serves as a robust **Data Mesh**, replacing legacy monolithic architectures with a flexible, secure, and resilient synchronization fabric.

Built with a **Ports and Adapters** (Hexagonal) architecture, Tisane enables seamless communication between your Dart code and the high-performance Rust core via `infusion_ffi`, ensuring military-grade encryption and conflict-free data merging.

## Agnostic Boundary

`tisane` is agnostic.
It transports, protects and synchronizes data, but it does not own domain schemas for consumers such as `Mellis`.

If a money-layer payload needs business validation, that validation must happen inside `Mellis`.
`tisane` should remain a generic transport and security layer.

Regra de ouro do canal agnostico de erro:

- estado esperado de negocio nao entra no canal agnostico
- falha operacional, contratual ou de integracao entra

Reference docs:

- [ERROR_SIGNALS.md](./ERROR_SIGNALS.md)
- [SENSITIVE_PAYMENT_DATA.md](./SENSITIVE_PAYMENT_DATA.md)

---

### 🌍 Languages / Idiomas / Idiomas

- [🇺🇸 English (Default)](#-english)
- [🇧🇷 Português](#-português)
- [🇪🇸 Español](#-español)

---

## 🇺🇸 English

### ✨ Key Features

- **🛡️ Secure FFI Bridge**: Direct, high-performance binding to the Rust protocol via `infusion_ffi`.
- **🔄 Decentralized Sync**: Real-time, peer-to-peer data synchronization using **CRDTs** (Conflict-free Replicated Data Types).
- **🔒 Encrypted Storage**: Military-grade offline persistence powered by **Hive**, with keys protected by the system's secure vault.
- **🔌 Modular Design**: Architecture based on Ports and Adapters, allowing for easy testing and swapping of infrastructure components.

### 🧠 Core Concepts

- **Vault**: Local secure context holding encryption/signing keys. Only derived keys and public identity are stored; the mnemonic is never stored.
- **Identity**: `author_pub`, `owner_pub`, and `requester_pub` define who signs and who can open data.
- **Frame**: The sealed, signed payload produced by Infusion (ciphertext + metadata + signature).
- **AAD**: Additional Authenticated Data. Visible metadata that is not encrypted, but is authenticated to prevent tampering.
- **Envelope**: `INFJ:{...}` wrapper storing `frame_b64`, `aad_b64`, `policy_id`, and optional `cap_b64`. Legacy `INF:` is still readable.
- **Cap Tokens**: Signed capability tokens that delegate access to a scope with rights and expiry.
- **Policies**: Default catalog `0=private`, `1=shared`, `2=public`. `shared` requires Cap Tokens.

### 📦 Installation

Add `tisane` to your `pubspec.yaml`:

```yaml
dependencies:
  tisane: ^1.1.2
```

### 🚀 Getting Started

#### 1. Initialization

Before accessing storage or the graph, initialize the `InfusionManager` to prepare the secure vault and FFI bridge.

```dart
import 'package:tisane/tisane.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the secure vault (generates keys if none exist)
  await InfusionManager.initialize();
  
  runApp(MyApp());
}
```

#### 2. Managing Identity (Infusion)

Tisane uses a localized key vault. You can generate or restore identities using BIP-39 mnemonics.

```dart
// Generate a new 12-word mnemonic
String mnemonic = await InfusionManager.generateMnemonic();
print('Keep this safe: $mnemonic');

// Restore identity from a mnemonic (Wipes current credentials!)
await InfusionManager.restoreFromMnemonic(mnemonic);
```

Tisane does not store the 12-word mnemonic. Keep it in a secure backup. Only
derived keys and public identity (author/owner) are persisted locally.

You can inspect the public identity:

```dart
final identity = await InfusionManager.exportIdentity();
```

#### 3. Configure Policies, AAD, and Cap Tokens (optional)

Configure before `initialize` if you need sharing or custom policy routing.
If you use `Uint8List`, add `import 'dart:typed_data';`.

```dart
final requesterPub32 = Uint8List(32); // replace with user public key

InfusionManager.configure(
  InfusionConfig(
    defaultPolicyId: InfusionPolicy.privateId,
    policyResolver: (ctx) {
      if (ctx.soul.startsWith('public/')) return InfusionPolicy.publicId;
      if (ctx.soul.startsWith('shared/')) return InfusionPolicy.sharedId;
      return InfusionPolicy.privateId;
    },
    capTokenProvider: (ctx) async =>
        await MyCapTokenStore.get(ctx.soul, ctx.field),
    requesterProvider: (ctx) async => requesterPub32,
  ),
);
```

If you only use private data, you can skip this step.

#### 4. Secure Storage

Store sensitive data locally with encryption keys derived directly from the hardware-backed vault.

```dart
// 1. Get the derived encryption key for Hive
final cipherKey = await InfusionManager.getHiveKey();

// 2. Open an encrypted box
final box = await Hive.openBox(
  'secure_user_data',
  encryptionCipher: HiveAesCipher(cipherKey),
);

// 3. Read/Write securely
await box.put('auth_token', 'super_secret_token');
```

#### 5. Data Mesh & Graph Operations

Interact with the decentralized graph using `TTClient`.

```dart
final client = TTClient();

// Write to the decentralized graph
// Data is automatically signed and encrypted if middleware is active
client.get('users').get('alice').put({
  'status': 'online',
  'role': 'engineer',
});

// Subscribe to real-time updates
client.get('users').on((data, key, msg) {
  print('Graph Update [$key]: $data');
});
```

#### 6. Infusion Security Model (AAD, Envelopes, Cap Tokens, Policies)

- **AAD (Additional Authenticated Data)**: metadata that is **not encrypted**, but **is authenticated** with the frame. It binds a frame to its context (soul/field/policy) and makes tampering detectable.
- **Structured envelope**: sealed values are stored as `INFJ:{...}` JSON containing `frame_b64`, `aad_b64`, `policy_id`, and optional `cap_b64`. This enables versioning, auditing, and future migrations. Legacy `INF:` hex is still readable.
- **Cap Tokens**: signed capability tokens that delegate access to a specific scope (CID), rights, and expiration. Recommended for shared data.
- **Policies**: default catalog is `0=private`, `1=shared`, `2=public`. The `shared` policy requires Cap Tokens by default.

You can customize policies, AAD, and Cap Token providers via:

```dart
InfusionManager.configure(
  InfusionConfig(
    defaultPolicyId: InfusionPolicy.privateId,
    embedCapToken: false,
  ),
);
```

### 🧪 FFI Native Library (Dev/CI)

Tisane relies on the native `infusion_ffi` binary. For desktop dev/test or CI,
either bundle the platform library via `infusion_ffi` assets or set
`INFUSION_LIB_PATH` to a built `.dylib`, `.so`, or `.dll`. The FFI verification
tests run when the native library is available and skip otherwise.

---

## 🇧🇷 Português

### Limite Agnóstico

`tisane` é agnóstica.
Ela transporta, protege e sincroniza dados, mas não define schemas de domínio para consumidoras como a `Mellis`.

Se um payload financeiro precisar de validação de negócio, essa validação deve acontecer dentro da `Mellis`.
`tisane` deve continuar sendo uma camada genérica de transporte e segurança.

Regra de ouro do canal agnóstico de erro:

- estado esperado de negócio não entra no canal agnóstico
- falha operacional, contratual ou de integração entra

### ✨ Funcionalidades Principais

- **🛡️ Ponte FFI Segura**: Comunicação direta e de alta performance com o protocolo Rust via `infusion_ffi`.
- **🔄 Sincronização Descentralizada**: Sincronização de dados P2P em tempo real usando **CRDTs**.
- **🔒 Armazenamento Criptografado**: Persistência offline segura com **Hive**, protegida pelo cofre (vault) do sistema.
- **🔌 Design Modular**: Arquitetura baseada em Portas e Adaptadores, facilitando testes e manutenção.

### 🧠 Conceitos Principais

- **Vault (Cofre)**: contexto seguro local com chaves de criptografia/assinatura. Apenas chaves derivadas e identidade pública são armazenadas; a mnemônica não é salva.
- **Identidade**: `author_pub`, `owner_pub` e `requester_pub` definem quem assina e quem pode abrir dados.
- **Frame**: payload selado e assinado produzido pela Infusion (ciphertext + metadados + assinatura).
- **AAD**: metadados visíveis não criptografados, mas autenticados para impedir adulterações.
- **Envelope**: wrapper `INFJ:{...}` com `frame_b64`, `aad_b64`, `policy_id` e `cap_b64` opcional. O legado `INF:` ainda é legível.
- **Cap Tokens**: tokens de capacidade assinados que delegam acesso a um escopo com direitos e expiração.
- **Políticas**: catálogo padrão `0=private`, `1=shared`, `2=public`. `shared` exige Cap Tokens.

### 📦 Instalação

Adicione `tisane` ao seu `pubspec.yaml`:

```yaml
dependencies:
  tisane: ^1.1.2
```

### 🚀 Começando

#### 1. Inicialização

```dart
import 'package:tisane/tisane.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o cofre de segurança
  await InfusionManager.initialize();
  
  runApp(MyApp());
}
```

#### 2. Identidade e Infusion

```dart
// Gerar uma nova frase mnemônica de 12 palavras
String mnemonic = await InfusionManager.generateMnemonic();

// Restaurar identidade (Cuidado: Substitui as chaves atuais!)
await InfusionManager.restoreFromMnemonic(mnemonic);
```

A Tisane não salva a frase de 12 palavras. Guarde em local seguro. Apenas
chaves derivadas e identidade pública (author/owner) são persistidas localmente.

Você pode inspecionar a identidade pública:

```dart
final identity = await InfusionManager.exportIdentity();
```

#### 3. Configuração de Políticas, AAD e Cap Tokens (opcional)

Configure antes do `initialize` se você precisa de compartilhamento ou regras customizadas.
Se usar `Uint8List`, adicione `import 'dart:typed_data';`.

```dart
final requesterPub32 = Uint8List(32); // substitua pela chave pública do usuário

InfusionManager.configure(
  InfusionConfig(
    defaultPolicyId: InfusionPolicy.privateId,
    policyResolver: (ctx) {
      if (ctx.soul.startsWith('public/')) return InfusionPolicy.publicId;
      if (ctx.soul.startsWith('shared/')) return InfusionPolicy.sharedId;
      return InfusionPolicy.privateId;
    },
    capTokenProvider: (ctx) async =>
        await MyCapTokenStore.get(ctx.soul, ctx.field),
    requesterProvider: (ctx) async => requesterPub32,
  ),
);
```

Se você usa apenas dados privados, pode pular esta etapa.

#### 4. Armazenamento Seguro

```dart
// Obter chave de criptografia derivada do cofre
final cipherKey = await InfusionManager.getHiveKey();

// Abrir box criptografado
final box = await Hive.openBox(
  'dados_seguros',
  encryptionCipher: HiveAesCipher(cipherKey),
);
```

#### 5. Operações de Data Mesh e Grafo

```dart
final client = TTClient();

client.get('users').get('alice').put({
  'status': 'online',
  'role': 'engineer',
});

client.get('users').on((data, key, msg) {
  print('Atualização do Grafo [$key]: $data');
});
```

#### 6. Modelo de Segurança da Infusion (AAD, Envelope, Cap Tokens, Políticas)

- **AAD (Additional Authenticated Data)**: metadados **não criptografados**, mas **autenticados** com o frame. Amarra o dado ao contexto (soul/campo/política) e torna adulterações detectáveis.
- **Envelope estruturado**: valores selados são armazenados como `INFJ:{...}` contendo `frame_b64`, `aad_b64`, `policy_id` e `cap_b64` opcional. Isso permite versionamento, auditoria e futuras migrações. O legado `INF:` continua legível.
- **Cap Tokens**: tokens de capacidade assinados que delegam acesso a um escopo (CID), direitos e expiração. Recomendado para dados compartilhados.
- **Políticas**: catálogo padrão `0=private`, `1=shared`, `2=public`. A política `shared` exige Cap Tokens por padrão.

Você pode personalizar políticas, AAD e provedores de Cap Tokens via:

```dart
InfusionManager.configure(
  InfusionConfig(
    defaultPolicyId: InfusionPolicy.privateId,
    embedCapToken: false,
  ),
);
```

### 🧪 Biblioteca Nativa FFI (Dev/CI)

O Tisane depende do binário nativo `infusion_ffi`. Para dev/test em desktop ou
CI, inclua a biblioteca da plataforma via assets do `infusion_ffi` ou defina
`INFUSION_LIB_PATH` apontando para o `.dylib`, `.so` ou `.dll`. Os testes de
verificação FFI são executados quando a biblioteca está disponível e são
ignorados caso contrário.

---

## 🇪🇸 Español

### ✨ Características Principales

- **🛡️ Puente FFI Seguro**: Enlace directo y de alto rendimiento con el protocolo Rust vía `infusion_ffi`.
- **🔄 Sincronización Descentralizada**: Sincronización P2P en tiempo real usando **CRDTs**.
- **🔒 Almacenamiento Cifrado**: Persistencia offline segura con **Hive**, protegida por la bóveda del sistema.
- **🔌 Diseño Modular**: Arquitectura de Puertos y Adaptadores para máxima flexibilidad.

### 🧠 Conceptos Principales

- **Vault (Bóveda)**: contexto seguro local con claves de cifrado/firma. Solo se guardan claves derivadas e identidad pública; la mnemónica no se guarda.
- **Identidad**: `author_pub`, `owner_pub` y `requester_pub` definen quién firma y quién puede abrir datos.
- **Frame**: payload sellado y firmado producido por Infusion (ciphertext + metadatos + firma).
- **AAD**: metadatos visibles no cifrados, pero autenticados para impedir manipulaciones.
- **Envelope**: wrapper `INFJ:{...}` con `frame_b64`, `aad_b64`, `policy_id` y `cap_b64` opcional. El legado `INF:` sigue siendo legible.
- **Cap Tokens**: tokens de capacidad firmados que delegan acceso a un alcance con derechos y expiración.
- **Políticas**: catálogo por defecto `0=private`, `1=shared`, `2=public`. `shared` requiere Cap Tokens.

### 📦 Instalación

```yaml
dependencies:
  tisane: ^1.1.2
```

### 🚀 Primeros Pasos

#### 1. Inicialización

```dart
import 'package:tisane/tisane.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar la bóveda de seguridad
  await InfusionManager.initialize();
  
  runApp(MyApp());
}
```

#### 2. Gestión de Identidad

```dart
// Generar una nueva frase mnemotécnica
String mnemonic = await InfusionManager.generateMnemonic();

// Restaurar identidad (¡Sobrescribe las credenciales actuales!)
await InfusionManager.restoreFromMnemonic(mnemonic);
```

Tisane no guarda la frase de 12 palabras. Conserva una copia segura. Solo se
persisten localmente las claves derivadas y la identidad pública (author/owner).

Puedes inspeccionar la identidad pública:

```dart
final identity = await InfusionManager.exportIdentity();
```

#### 3. Configuración de Políticas, AAD y Cap Tokens (opcional)

Configura antes de `initialize` si necesitas compartir o reglas personalizadas.
Si usas `Uint8List`, añade `import 'dart:typed_data';`.

```dart
final requesterPub32 = Uint8List(32); // reemplaza por la clave pública del usuario

InfusionManager.configure(
  InfusionConfig(
    defaultPolicyId: InfusionPolicy.privateId,
    policyResolver: (ctx) {
      if (ctx.soul.startsWith('public/')) return InfusionPolicy.publicId;
      if (ctx.soul.startsWith('shared/')) return InfusionPolicy.sharedId;
      return InfusionPolicy.privateId;
    },
    capTokenProvider: (ctx) async =>
        await MyCapTokenStore.get(ctx.soul, ctx.field),
    requesterProvider: (ctx) async => requesterPub32,
  ),
);
```

Si solo usas datos privados, puedes omitir este paso.

#### 4. Almacenamiento Seguro

```dart
final cipherKey = await InfusionManager.getHiveKey();

final box = await Hive.openBox(
  'datos_seguros',
  encryptionCipher: HiveAesCipher(cipherKey),
);
```

#### 5. Operaciones de Data Mesh y Grafo

```dart
final client = TTClient();

client.get('users').get('alice').put({
  'status': 'online',
  'role': 'engineer',
});

client.get('users').on((data, key, msg) {
  print('Actualización del Grafo [$key]: $data');
});
```

#### 6. Modelo de Seguridad de Infusion (AAD, Envelope, Cap Tokens, Políticas)

- **AAD (Additional Authenticated Data)**: metadatos **no cifrados**, pero **autenticados** con el frame. Vincula el dato al contexto (soul/campo/política) y hace detectable la manipulación.
- **Envelope estructurado**: los valores sellados se almacenan como `INFJ:{...}` con `frame_b64`, `aad_b64`, `policy_id` y `cap_b64` opcional. Esto habilita versionado, auditoría y futuras migraciones. El legado `INF:` sigue siendo legible.
- **Cap Tokens**: tokens de capacidad firmados que delegan acceso a un alcance (CID), derechos y expiración. Recomendado para datos compartidos.
- **Políticas**: catálogo por defecto `0=private`, `1=shared`, `2=public`. La política `shared` requiere Cap Tokens por defecto.

Puedes personalizar políticas, AAD y proveedores de Cap Tokens con:

```dart
InfusionManager.configure(
  InfusionConfig(
    defaultPolicyId: InfusionPolicy.privateId,
    embedCapToken: false,
  ),
);
```

### 🧪 Biblioteca Nativa FFI (Dev/CI)

Tisane depende del binario nativo `infusion_ffi`. Para desarrollo/pruebas en
escritorio o CI, empaqueta la librería de la plataforma vía assets de
`infusion_ffi` o define `INFUSION_LIB_PATH` apuntando al `.dylib`, `.so` o
`.dll`. Las pruebas de verificación FFI se ejecutan cuando la biblioteca está
disponible y se omiten en caso contrario.
