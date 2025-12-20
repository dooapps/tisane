# 🍵 Tisane

![Pub Version](https://img.shields.io/pub/v/tisane)
![License](https://img.shields.io/github/license/dooapps/tisane)
![Build Status](https://img.shields.io/github/workflow/status/dooapps/tisane/Dart)
![Style](https://img.shields.io/badge/style-effective__dart-40c4ff.svg)

**Tisane** is a decentralized, offline-first integration layer designed for the next generation of Flutter applications. It serves as a robust **Data Mesh**, replacing legacy monolithic architectures with a flexible, secure, and resilient synchronization fabric.

Built with a **Ports and Adapters** (Hexagonal) architecture, Tisane enables seamless communication between your Dart code and the high-performance Rust core via `infusion_ffi`, ensuring military-grade encryption and conflict-free data merging.

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

### 📦 Installation

Add `tisane` to your `pubspec.yaml`:

```yaml
dependencies:
  tisane: ^1.0.2
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

#### 3. Secure Storage

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

#### 4. Data Mesh & Graph Operations

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

---

## 🇧🇷 Português

### ✨ Funcionalidades Principais

- **🛡️ Ponte FFI Segura**: Comunicação direta e de alta performance com o protocolo Rust via `infusion_ffi`.
- **🔄 Sincronização Descentralizada**: Sincronização de dados P2P em tempo real usando **CRDTs**.
- **🔒 Armazenamento Criptografado**: Persistência offline segura com **Hive**, protegida pelo cofre (vault) do sistema.
- **🔌 Design Modular**: Arquitetura baseada em Portas e Adaptadores, facilitando testes e manutenção.

### 📦 Instalação

Adicione `tisane` ao seu `pubspec.yaml`:

```yaml
dependencies:
  tisane: ^1.0.2
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

#### 3. Armazenamento Seguro

```dart
// Obter chave de criptografia derivada do cofre
final cipherKey = await InfusionManager.getHiveKey();

// Abrir box criptografado
final box = await Hive.openBox(
  'dados_seguros',
  encryptionCipher: HiveAesCipher(cipherKey),
);
```

---

## 🇪🇸 Español

### ✨ Características Principales

- **🛡️ Puente FFI Seguro**: Enlace directo y de alto rendimiento con el protocolo Rust vía `infusion_ffi`.
- **🔄 Sincronización Descentralizada**: Sincronización P2P en tiempo real usando **CRDTs**.
- **🔒 Almacenamiento Cifrado**: Persistencia offline segura con **Hive**, protegida por la bóveda del sistema.
- **🔌 Diseño Modular**: Arquitectura de Puertos y Adaptadores para máxima flexibilidad.

### 📦 Instalación

```yaml
dependencies:
  tisane: ^1.0.2
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
