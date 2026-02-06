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
git clone --recurse-submodules git@github.com:longquangpham90/generate-template.git tools
```

or

```bash
mkdir tools && cd tools && git clone https://github.com/longquangpham90/generate-template.git .
```
---

Install `ktlint`

##

- **Install via Homebrew (macOS)**:
  ```bash
  brew install ktlint
  ```
- **Install via cURL (macOS, Linux)**:
  ```bash
  curl -sS https://github.com/ktlint/ktlint/releases/download/0.46.1/ktlint && chmod +x ktlint && sudo mv ktlint /usr/local/bin/
  ```

## 🚀 Usage

### Convert folder SVG to XML
```bash
bin/bash [path-to-project]/tools/scripts/convert/svg2android.sh <input_svg_folder>
```

### Run the script to generate templates:

```bash
/bin/bash [path-to-project]/tools/scripts/createTempPrompt.sh
```

### How to Use the Script Json Annotation Tool

- **General Syntax**:
  ```bash
  ./scripts/json-annotation.sh <path_to_file_or_folder> <option>
  ```

- **Options**:
    - **`-r`**: Remove `@SerializedName` and import `SerializedName` from the file or folder.
    - **`-a`**: Add `@SerializedName` to `val` properties and import `SerializedName` if it's
      missing.
    - **`-ra`**: Combine both actions: **remove** and **re-add** `@SerializedName` and import.

Usage Examples

- **Remove `@SerializedName` and import**:
  ```bash
  ./scripts/manage_serializedname.sh path/to/file.kt -r
  ```

- **Add `@SerializedName` and import**:
  ```bash
  ./scripts/manage_serializedname.sh path/to/file.kt -a
  ```

- **Combine: Remove and Re-add**:
  ```bash
  ./scripts/manage_serializedname.sh path/to/file.kt -ra
  ```

- **Apply to a folder**:
  ```bash
  ./scripts/manage_serializedname.sh models/ -r
  ```
  
- **Check 16K page size**:
  ```bash
  ./scripts/check_elf_alignment.sh
  ```
 
- **Remove Butterkinfe**:
 ```bash
  ./scripts/removeButterkinfe.sh
  ``` 

- **Gen Entity - Model - Mapper for flutter **:
```shell
chmod +x ./tools/scripts/flutter/gen_entity.sh
./tools/scripts/flutter/gen_entity.sh
```

## Notes

- After making changes, `ktlint` will automatically format the code to ensure it's clean and follows
  the style guide.
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
