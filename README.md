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
**Tisane** is the new experimentation and integration home for the **FinBberLink** ecosystem. Designed to supersede *TipTool*, Tisane serves as a decentralized, offline-first Data Mesh layer for Flutter applications.

**Key Features:**
- **Secure FFI Bridge**: Direct communication with the Rust protocol via `infusion_ffi`.
- **Decentralized Sync**: Uses CRDTs (Conflict-free Replicated Data Types) for conflict-free data merging between peers.
- **Encrypted Storage**: Secure local persistence using Hive, with keys protected by the system vault.
- **Modular Architecture**: Ports and Adapters design for maximum flexibility and testability.

---

## 🇪🇸 Español (Es)
**Tisane** es la nueva capa de integración y experimentación para el ecosistema **FinBberLink**. Diseñado para reemplazar a *TipTool*, Tisane actúa como una malla de datos descentralizada (Data Mesh) y *offline-first* para aplicaciones Flutter.

**Características Principales:**
- **Puente FFI Seguro**: Comunicación directa con el protocolo Rust a través de `infusion_ffi`.
- **Sincronización Descentralizada**: Utiliza CRDTs (Tipos de Datos Replicados Libres de Conflictos) para la fusión de datos sin conflictos entre pares.
- **Almacenamiento Encriptado**: Persistencia local segura utilizando Hive, con claves protegidas por la bóveda del sistema.
- **Arquitectura Modular**: Diseño basado en Puertos y Adaptadores para máxima flexibilidad y capacidad de prueba.

---

---
 
 ## 🚀 Getting Started

 Add `tisane` to your `pubspec.yaml`:
 ```yaml
 dependencies:
   tisane: ^1.0.0
 ```

 ## 💡 Usage

 Initialize the Infusion Manager at the start of your app:

 ```dart
 import 'package:tisane/tisane.dart';

 void main() async {
   await InfusionManager.initialize();
   
   // Generate a mnemonic
   final mnemonic = await InfusionManager.generateMnemonic();
   print('New Wallet: $mnemonic');
 }
 ```

 ## 🛠️ Development
 1. `flutter pub get`
 2. `flutter test`
