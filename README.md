# 🛠️ Tool Generate Template

A simple tool to generate **Java/Kotlin templates** CA MVVM for Android projects.

---

## 📌 Features

- Supports both **Java** and **Kotlin** code generation
- Generates **Fragment**, **ViewModel**, and **XML layout** templates
- Uses `envsubst` for template variable injection
- Organized in `tools/scripts/` and reusable via Git submodule

---

## 🔧 Setup

Clone the project with submodules to ensure template files are included:

```bash
git clone --recurse-submodules git@github:longquangpham90/generate-template.git tools
```

or

```bash
mkdir tools && cd tools && git clone https://github.com/longquangpham90/generate-template.git .
```
---

## 🚀 Usage

Run the script to generate templates:

```bash
/bin/bash [path-to-project]/tools/scripts/createTempPrompt.sh
```
---

## ✅ Requirements

- Bash shell
- `envsubst` (comes with `gettext` package)
- Permissions to write files into the desired module (e.g., `src/main/java/...`)

---

## 🧪 Test Cases

- ✅ Generates Kotlin fragment, ViewModel, and XML layout from template
- ✅ Fails gracefully when template files are missing
- ✅ Correctly replaces variables using `envsubst`

---

## 📦 APK Output

_Coming soon..._

---

## 📄 License

Copyright (c) 2025 Smile Studio.
All rights reserved.
