# Drop Plus 🚀

**Drop Plus** is a high-performance, privacy-focused, peer-to-peer (P2P) file transfer application built with **Flutter** and **Rust**. It leverages the cutting-edge **Iroh** protocol to enable direct, secure, and lightning-fast data transfers between devices without the need for centralized servers or cloud storage.

---

## ✨ Features

- **P2P Transfer:** Direct device-to-device transfers using the [Iroh](https://iroh.computer/) protocol.
- **Cross-Platform:** Seamlessly send and receive files across different platforms.
- **QR Code Sharing:** Generate and scan QR codes for quick peer discovery and transfer initiation.
- **Secure by Design:** End-to-end security provided by the Iroh networking stack.
- **Material 3 UI:** A modern, clean, and responsive user interface built with Flutter.
- **Folder Support:** Share entire directories as easily as single files.
- **Real-time Progress:** Track your transfers with detailed visual feedback and logs.
- **Privacy First:** No intermediate servers; your data stays on your devices.

---

## 🛠 Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
  - State Management: `flutter_bloc`
  - Theming: `flex_color_scheme`
  - Icons: `material_symbols_icons`
- **Backend (Core):** [Rust](https://www.rust-lang.org/)
  - P2P Protocol: `iroh` & `iroh-blobs`
  - Async Runtime: `tokio`
- **Bridge:** [flutter_rust_bridge v2](https://cjycode.com/flutter_rust_bridge/) (FRB) for high-performance communication between Dart and Rust.

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable)
- [Rust toolchain](https://www.rust-lang.org/tools/install)
- [Task](https://taskfile.dev/installation/) (optional, but recommended for automation)
- `flutter_rust_bridge_codegen`:
  ```bash
  cargo install flutter_rust_bridge_codegen
  ```

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/lecuong04/Drop-Plus.git
   cd Drop-Plus
   ```

2. **Install Dart dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Rust-Dart bindings:**
   Using Task:
   ```bash
   task generate
   ```
   Or manually:
   ```bash
   flutter_rust_bridge_codegen generate
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

---

## 🏗 Architecture

Drop Plus follows a hybrid architecture to combine the best of both worlds:

- **`lib/` (Flutter):** Handles the UI, state management, and user interaction. It communicates with the Rust core via generated bindings.
- **`core/` (Rust):** Contains the heavy-lifting logic, including P2P networking, file indexing, and data streaming using the Iroh protocol.
- **`rust_builder/`:** A helper package for building and integrating the Rust binary into the Flutter application.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. (Note: Check if a LICENSE file exists or update as needed).

---

Developed with ❤️ using Flutter and Rust.
