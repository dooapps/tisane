# Tisane

## 🇧🇷 Português (Pt-Br)
**Tisane** é a nova camada de integração e experimentação para o ecossistema **FinBberLink**. Projetado para substituir o *TipTool*, o Tisane atua como uma malha de dados descentralizada (Data Mesh) e *offline-first* para aplicativos Flutter.

**Principais Funcionalidades:**

- **Ponte FFI Segura**: Comunicação direta com o protocolo Rust via `infusion_ffi`.
- **Sincronização Descentralizada**: Utiliza CRDTs (Conflict-free Replicated Data Types) para fusão de dados sem conflitos entre pares.
- **Armazenamento Criptografado**: Persistência local segura usando Hive, com chaves protegidas pelo cofre do sistema.
- **Arquitetura Modular**: Design baseado em Portas e Adaptadores para máxima flexibilidade e testabilidade.

---

## 🇺🇸 English (En-Us)
**Tisane** is the new integration and experimentation layer for the **FinBberLink** ecosystem. Designed to replace *TipTool*, Tisane acts as a decentralized (Data Mesh) and *offline-first* data mesh for Flutter applications.

**Key Features:**

- **Secure FFI Bridge**: Direct communication with the Rust protocol via `infusion_ffi`.
- **Decentralized Synchronization**: Uses CRDTs (Conflict-free Replicated Data Types) for conflict-free data merging between peers.
- **Encrypted Storage**: Secure local persistence using Hive, with keys protected by the system vault.
- **Modular Architecture**: Ports and Adapters based design for maximum flexibility and testability.

---

## 🇪🇸 Español (Es)
**Tisane** es la nueva capa de integración y experimentación para el ecosistema **FinBberLink**. Diseñado para reemplazar a *TipTool*, Tisane actúa como una malla de datos descentralizada (Data Mesh) y *offline-first* para aplicaciones Flutter.

**Funcionalidades Principales:**

- **Puente FFI Seguro**: Comunicación directa con el protocolo Rust a través de `infusion_ffi`.
- **Sincronización Descentralizada**: Utiliza CRDTs (Conflict-free Replicated Data Types) para la fusión de datos sin conflictos entre pares.
- **Almacenamiento Criptográfico**: Persistencia local segura usando Hive, con claves protegidas por la bóveda del sistema.
- **Arquitectura Modular**: Diseño basado en Puertos y Adaptadores para máxima flexibilidad y testabilidad.

---

## 📚 Documentation

Tisane provides a robust set of tools for building secure, decentralized applications. Below is an overview of the key touchpoints.

### Installation

Add `tisane` to your `pubspec.yaml`:

```yaml
dependencies:
  tisane: ^1.2.5
```

### Initialization

Before using any Tisane features, you must initialize the `InfusionManager`. This sets up the secure vault and prepares the FFI bridge.

```dart
import 'package:tisane/tisane.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the secure vault
  await InfusionManager.initialize();
  
  runApp(MyApp());
}
```

### Core Components

#### 1. Infusion Manager (Security & Vault)

The `InfusionManager` is your primary interface for security operations. It handles encryption keys, mnemonic generation, and secure storage access.

**Key Methods:**
- `initialize()`: Sets up the vault.
- `generateMnemonic()`: Creates a new 12-word BIP-39 mnemonic.
- `exportCredentials()`: Returns encryption keys (Handle with care!).
- `getHiveKey()`: Derives a secure key for Hive storage.
- `getBlindIndex(String)`: Generates a blind index for searchable encryption.

```dart
// Generate a new wallet/identity
String mnemonic = await InfusionManager.generateMnemonic();

// Restore from mnemonic
await InfusionManager.restoreFromMnemonic(mnemonic);
```

#### 2. TTClient (Data Mesh)

`TTClient` is the entry point for the decentralized graph. It manages peers, data synchronization, and graph operations.

```dart
// Create a client (optionally connecting to peers)
final client = TTClient(
  options: TTOptions(
    peers: ['ws://your-peer-node.com/gun']
  )
);

// Write data to a node
client.get('user/profile').put({
  'name': 'Alice',
  'role': 'Developer'
});

// Read data (Real-time subscription)
client.get('user/profile').on((data, key, msg) {
  print('Updated profile: $data');
});
```

#### 3. Secure Storage (Hive Integration)

Tisane integrates seamlessly with Hive for offline-first persistence, using keys derived efficiently from the Infusion vault.

```dart
// Get the secure key for Hive
final hiveKey = await InfusionManager.getHiveKey();

// Open a secure box
final box = await Hive.openBox('secure_data', encryptionCipher: HiveAesCipher(hiveKey));
```
