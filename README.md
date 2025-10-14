# Elden Ring Save File Backup Tool

A user-friendly application that automatically backs up your Elden Ring save files. Never lose your progress again with intelligent backup monitoring, compression, and mod launcher support.

## 🌐 Translations

- [Español](#-español)
- [Français](#-français)
- [日本語](#-日本語)
- [简体中文](#-简体中文)
- [한국어](#-한국어)

## 📋 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [📁 Save File Locations](#-save-file-locations)
- [🎮 Using the Application](#-using-the-application)
- [🔧 Advanced Features](#-advanced-features)
- [🌍 Multi-Language Support](#-multi-language-support)
- [⚠️ Important Notes](#️-important-notes)
- [🛠️ Troubleshooting](#️-troubleshooting)
- [📋 System Requirements](#-system-requirements)
- [📞 Support](#-support)

## 🚀 Quick Start

### Installation
1. **Download** the `EldenRingSaveBackup.msi` installer from the `dist` folder
2. **Run** the installer as Administrator
3. **Launch** the application from your Start Menu or Desktop shortcut
4. **Configure** your save file location and backup settings
5. **Start** monitoring to automatically backup your saves!

### What It Does
- **Automatically detects** when your Elden Ring save file changes
- **Creates compressed backups** (90% smaller than original files)
- **Keeps multiple backups** with automatic cleanup of old ones
- **Works with mods** like ModEngine2, Convergence, and Seamless Coop
- **Runs in background** with system tray integration

## 📁 Save File Locations

The tool automatically finds your save files in these common locations:
- **Elden Ring**: `%USERPROFILE%\AppData\Roaming\EldenRing\[SteamID]\ER0000.sl2`
- **Seamless Coop**: `%USERPROFILE%\AppData\Roaming\EldenRing\[SteamID]\ER0000.co2`

## 🎮 Using the Application

### First Time Setup
1. **Launch** the application from your Start Menu
2. **Select Language** from the dropdown (6 languages supported)
3. **Configure Save File**:
   - **Auto-Detection**: Click the 🔍 button next to "Browse" to automatically find your save file
   - **Manual Browse**: Click "Browse" to manually select your `ER0000.sl2` or `ER0000.co2` file
   - **Multiple Saves**: If you have multiple Steam accounts, the auto-detection will show a selection dialog
4. **Configure Game Executable** (Optional):
   - **Auto-Detection**: Click the 🔍 button to automatically find your Elden Ring installation
   - **Manual Browse**: Click "Browse" to manually select your game executable or mod launcher
   - **For Mods**: Use manual browse to select mod launchers like ModEngine2
5. **Set Backup Folder** - Choose where to store your backups (Documents folder recommended)
6. **Configure Settings**:
   - **Max Backups**: How many backups to keep (default: 50)
   - **Backup Method**: File Change Detection (recommended) or Timer Interval
   - **Timer Interval**: If using timer mode, set interval (30 seconds to 1 hour)
7. **Click "Start Monitoring"** to begin automatic backups

### Daily Usage
- **System Tray Icon**: The app runs in your system tray (bottom-right corner)
- **Double-click tray icon** to show/hide the main window
- **Right-click tray icon** for quick actions
- **Automatic backups** happen when you save your game
- **Manual backup** button for immediate backup anytime

## 🔧 Advanced Features

### 🔍 Auto-Detection Buttons
The application includes smart auto-detection buttons (🔍) that can automatically find your files:

#### **Save File Auto-Detection**
- **Automatically scans** for Elden Ring save files in standard locations
- **Supports multiple Steam accounts** - shows selection dialog if multiple found
- **Works with vanilla Elden Ring** save files (.sl2 format)
- **Hover over the 🔍 button** for tooltip information

#### **Game Executable Auto-Detection**
- **Scans common Steam installation paths** (C:, D:, E:, F: drives)
- **Reads Steam library configuration** from registry and libraryfolders.vdf
- **Finds vanilla Elden Ring installations** automatically
- **Shows selection dialog** if multiple installations found

#### **When to Use Manual Browse Instead**
- **Mod Launchers**: Always use manual browse for ModEngine2, Convergence, etc.
- **Custom Installations**: Non-standard Steam library locations
- **Multiple Game Versions**: When you have both vanilla and modded installations
- **Custom Save Locations**: If your saves are in non-standard locations

### Mod Launcher Support
Configure the app to launch Elden Ring with mods:

1. **Game Executable**: **Use manual browse** to select your mod launcher (e.g., ModEngine2)
2. **Launch Arguments**: Add mod-specific arguments (e.g., `-t er -c .\config_eldenring.toml`)
3. **Launch Game**: Use the "Launch Elden Ring" button to start with mods

> **💡 Tip**: Auto-detection works great for vanilla Elden Ring, but for mods always use the manual browse button to ensure you select the correct mod launcher.

### Backup Management
- **Compressed backups** save 90% disk space (30MB → 3MB)
- **Smart naming** with timestamps and file type prefixes
- **Automatic cleanup** removes old backups based on your settings
- **Easy restoration** - just copy a backup file back to your save location

## 🌍 Multi-Language Support

The interface is available in:
- English
- Spanish  
- French
- Japanese
- Chinese
- Korean

## ⚠️ Important Notes

### Safety
- **Always test** with a copy of your save file first
- **Keep multiple backup locations** for important saves
- **The app creates timestamped backups** - no overwriting of existing files
- **Automatic cleanup** removes old backups based on your max backup setting

### Requirements
- **Windows 10/11** (64-bit recommended)
- **Elden Ring** installed and at least one save file created
- **Administrator privileges** for installation

## 🛠️ Troubleshooting

### Common Issues
- **"Save file not found"**: Make sure you've played Elden Ring and created a save file first
- **"Backup folder not configured"**: Select a backup folder before starting monitoring
- **Permission errors**: Run the installer as Administrator
- **File in use**: Close Elden Ring completely before starting monitoring
- **No backups created**: Ensure monitoring is started and save file path is correct

### Getting Help
- Check the **Activity Log** in the application for detailed information
- Ensure **Elden Ring is closed** when starting monitoring
- Verify your **save file path** is correct
- Make sure you have **write permissions** to the backup folder

## 📋 System Requirements

- **Operating System**: Windows 10 or Windows 11
- **Memory**: 50MB RAM minimum
- **Storage**: 100MB for application + space for backups
- **Elden Ring**: Must be installed with at least one save file

## 📞 Support

This tool is provided as-is for personal use. Always keep manual backups of your important save files as well.

---
## 🇰🇷 한국어

> **📝 번역 참고**: 이 번역은 자동화된 도구로 생성되었습니다. 더 나은 번역이 있으시면 GitHub에서 제출해 주세요.

### 🚀 빠른 시작

#### 설치
1. `dist` 폴더에서 설치 파일 `EldenRingSaveBackup.msi`를 **다운로드**합니다.
2. 설치 프로그램을 **관리자 권한으로 실행**합니다.
3. **시작 메뉴** 또는 **바탕화면 바로가기**에서 앱을 **실행**합니다.
4. **세이브 파일 위치**와 **백업 설정**을 **구성**합니다.
5. **Start Monitoring**을 클릭하여 **자동 백업**을 시작합니다.

#### 주요 기능
- Elden Ring 세이브 파일 변경을 **자동 감지**합니다.
- **압축 백업**을 생성합니다(최대 약 90% 용량 절감).
- **여러 백업을 보관**하고 오래된 백업을 **자동 정리**합니다.
- ModEngine2, Convergence, Seamless Coop 등 **모드 런처 지원**.
- **시스템 트레이**에서 백그라운드 실행.

### 📁 세이브 파일 위치
- **Elden Ring**: `%USERPROFILE%\\AppData\\Roaming\\EldenRing\\[SteamID]\\ER0000.sl2`
- **Seamless Coop**: `%USERPROFILE%\\AppData\\Roaming\\EldenRing\\[SteamID]\\ER0000.co2`

### 🎮 앱 사용 방법

#### 초기 설정
1. **언어 선택**(6개 언어 지원).
2. **세이브 파일 설정**:
   - **자동 감지**: "Browse" 옆의 🔍 버튼을 클릭하여 세이브 파일을 자동으로 찾기
   - **수동 탐색**: "Browse"를 클릭하여 `ER0000.sl2` 또는 `ER0000.co2` 파일을 수동으로 선택
   - **여러 세이브**: 여러 Steam 계정이 있는 경우 자동 감지에서 선택 대화상자가 표시됩니다
3. **게임 실행 파일 설정**(선택사항):
   - **자동 감지**: 🔍 버튼을 클릭하여 Elden Ring 설치를 자동으로 찾기
   - **수동 탐색**: "Browse"를 클릭하여 게임 실행 파일 또는 모드 런처를 수동으로 선택
   - **모드용**: ModEngine2 등의 모드 런처는 수동 탐색 사용
4. **백업 폴더 선택**(권장: 문서 폴더).
5. **보관 개수/방식/간격** 설정(최대 개수, 감지 방식, 타이머).
6. **"Start Monitoring" 클릭**으로 시작합니다.

#### 🔍 자동 감지 버튼
앱에는 파일을 자동으로 찾을 수 있는 스마트 자동 감지 버튼(🔍)이 포함되어 있습니다:

##### **세이브 파일 자동 감지**
- **표준 위치**에서 Elden Ring 세이브 파일을 **자동 스캔**
- **여러 Steam 계정** 지원 - 여러 개가 발견되면 선택 대화상자 표시
- **바닐라 Elden Ring 세이브 파일**(.sl2 형식) 지원
- **🔍 버튼에 마우스 오버**하여 툴팁 정보 확인

##### **게임 실행 파일 자동 감지**
- **일반적인 Steam 설치 경로**(C:, D:, E:, F: 드라이브) 스캔
- **레지스트리와 libraryfolders.vdf**에서 Steam 라이브러리 설정 읽기
- **바닐라 Elden Ring 설치** 자동 감지
- **여러 설치**가 발견되면 선택 대화상자 표시

##### **수동 탐색을 사용해야 하는 경우**
- **모드 런처**: ModEngine2, Convergence 등은 항상 수동 탐색 사용
- **사용자 정의 설치**: 비표준 Steam 라이브러리 위치
- **여러 게임 버전**: 바닐라와 모드 버전 설치가 모두 있는 경우
- **사용자 정의 세이브 위치**: 세이브 파일이 비표준 위치에 있는 경우

> **💡 팁**: 자동 감지는 바닐라 Elden Ring에 완벽하지만, 모드의 경우 항상 수동 탐색 버튼을 사용하여 올바른 모드 런처를 선택하세요.

### 🛠️ 문제 해결
- **"세이브 파일을 찾을 수 없음"**: 먼저 게임에서 한 번 저장하세요.
- **"백업 폴더가 설정되지 않음"**: 모니터링 시작 전에 폴더를 선택하세요.
- **권한 문제**: 설치 프로그램을 관리자 권한으로 실행하세요.

---
## 🇨🇳 简体中文

> **📝 翻译说明**: 此翻译由自动化工具生成。如有更好的翻译，请在GitHub上提交。

### 🚀 快速开始

#### 安装
1. 从 `dist` 文件夹**下载**安装包 `EldenRingSaveBackup.msi`。
2. 以**管理员身份运行**安装程序。
3. 从**开始菜单**或**桌面快捷方式**启动应用。
4. **配置**存档文件位置和备份设置。
5. 点击 **Start Monitoring** 开始**自动备份**。

#### 功能简介
- **自动检测** Elden Ring 存档文件的更改。
- 创建**压缩备份**（体积最多可减少约 90%）。
- **保留多份备份**，并**自动清理**旧备份。
- **支持 MOD 启动器**（如 ModEngine2、Convergence、Seamless Coop）。
- **后台运行**，带系统托盘图标。

### 📁 存档文件位置
- **Elden Ring**：`%USERPROFILE%\\AppData\\Roaming\\EldenRing\\[SteamID]\\ER0000.sl2`
- **Seamless Coop**：`%USERPROFILE%\\AppData\\Roaming\\EldenRing\\[SteamID]\\ER0000.co2`

### 🎮 应用使用方法

#### 初始设置
1. **选择语言**（支持 6 种语言）。
2. **配置存档文件**：
   - **自动检测**：点击"Browse"旁边的🔍按钮自动查找存档文件
   - **手动浏览**：点击"Browse"手动选择`ER0000.sl2`或`ER0000.co2`文件
   - **多个存档**：如果有多个Steam账户，自动检测会显示选择对话框
3. **配置游戏执行文件**（可选）：
   - **自动检测**：点击🔍按钮自动查找Elden Ring安装
   - **手动浏览**：点击"Browse"手动选择游戏执行文件或MOD启动器
   - **MOD使用**：使用手动浏览选择ModEngine2等MOD启动器
4. **选择备份文件夹**（推荐：文档）。
5. **设置保留数量 / 方式 / 间隔**（最大数量、检测方式、定时器）。
6. **点击 "Start Monitoring"** 开始。

#### 🔍 自动检测按钮
应用包含智能自动检测按钮（🔍），可以自动查找您的文件：

##### **存档文件自动检测**
- **自动扫描**标准位置的Elden Ring存档文件
- **支持多个Steam账户** - 如果找到多个会显示选择对话框
- **适用于原版Elden Ring存档文件**（.sl2格式）
- **悬停在🔍按钮上**查看工具提示信息

##### **游戏执行文件自动检测**
- **扫描常见Steam安装路径**（C:、D:、E:、F:驱动器）
- **从注册表和libraryfolders.vdf读取Steam库配置**
- **自动查找原版Elden Ring安装**
- **如果找到多个安装会显示选择对话框**

##### **何时使用手动浏览**
- **MOD启动器**：ModEngine2、Convergence等始终使用手动浏览
- **自定义安装**：非标准Steam库位置
- **多个游戏版本**：当您同时拥有原版和MOD版安装时
- **自定义存档位置**：如果您的存档在非标准位置

> **💡 提示**：自动检测对原版Elden Ring效果很好，但对于MOD，请始终使用手动浏览按钮以确保选择正确的MOD启动器。

### 🛠️ 故障排除
- **“未找到存档文件”**：请先在游戏内创建一次存档。
- **“未配置备份文件夹”**：开始监控前请选择备份文件夹。
- **权限问题**：请以管理员身份运行安装程序。

---
## 🇯🇵 日本語

> **📝 翻訳について**: この翻訳は自動化ツールで生成されています。より良い翻訳があればGitHubで提出してください。

### 🚀 クイックスタート

#### インストール
1. `dist` フォルダーからインストーラー `EldenRingSaveBackup.msi` を**ダウンロード**します。
2. インストーラーを**管理者として実行**します。
3. **スタートメニュー**または**デスクトップのショートカット**からアプリを**起動**します。
4. **セーブファイルの場所**と**バックアップ設定**を**設定**します。
5. **Start Monitoring** をクリックして**自動バックアップ**を開始します。

#### 機能概要
- Elden Ring のセーブファイルの変更を**自動検出**します。
- **圧縮バックアップ**を作成（最大約90%の容量削減）。
- **複数のバックアップ**を保持し、古いものを**自動クリーンアップ**します。
- ModEngine2、Convergence、Seamless Coop などの**MODに対応**します。
- **システムトレイ**でバックグラウンド実行します。

### 📁 セーブファイルの場所
- **Elden Ring**: `%USERPROFILE%\\AppData\\Roaming\\EldenRing\\[SteamID]\\ER0000.sl2`
- **Seamless Coop**: `%USERPROFILE%\\AppData\\Roaming\\EldenRing\\[SteamID]\\ER0000.co2`

### 🎮 アプリの使い方

#### 初期設定
1. **言語を選択**（6言語対応）。
2. **セーブファイルを設定**：
   - **自動検出**: 「Browse」の横の🔍ボタンをクリックしてセーブファイルを自動検出
   - **手動選択**: 「Browse」をクリックして`ER0000.sl2`または`ER0000.co2`ファイルを手動選択
   - **複数セーブ**: 複数のSteamアカウントがある場合、自動検出で選択ダイアログが表示されます
3. **ゲーム実行ファイルを設定**（オプション）：
   - **自動検出**: 🔍ボタンをクリックしてElden Ringのインストールを自動検出
   - **手動選択**: 「Browse」をクリックしてゲーム実行ファイルまたはMODランチャーを手動選択
   - **MOD用**: ModEngine2などのMODランチャーは手動選択を使用
4. **バックアップ先フォルダーを選択**（推奨: ドキュメント）。
5. **保持数・方法・間隔**を設定（最大数、検知方式、タイマー）。
6. **"Start Monitoring" をクリック**して開始します。

#### 🔍 自動検出ボタン
アプリには、ファイルを自動的に見つけることができるスマートな自動検出ボタン（🔍）が含まれています：

##### **セーブファイル自動検出**
- **標準的な場所**でElden Ringのセーブファイルを**自動スキャン**
- **複数のSteamアカウント**に対応 - 複数見つかった場合は選択ダイアログを表示
- **バニラElden Ringのセーブファイル**（.sl2形式）に対応
- **🔍ボタンにマウスオーバー**でツールチップ情報を表示

##### **ゲーム実行ファイル自動検出**
- **一般的なSteamインストールパス**（C:、D:、E:、F:ドライブ）をスキャン
- **Steamライブラリ設定**をレジストリとlibraryfolders.vdfから読み取り
- **バニラElden Ringのインストール**を自動検出
- **複数のインストール**が見つかった場合は選択ダイアログを表示

##### **手動選択を使用する場合**
- **MODランチャー**: ModEngine2、Convergenceなどは常に手動選択を使用
- **カスタムインストール**: 非標準のSteamライブラリの場所
- **複数のゲームバージョン**: バニラとMOD版の両方のインストールがある場合
- **カスタムセーブ場所**: セーブファイルが非標準の場所にある場合

> **💡 ヒント**: 自動検出はバニラElden Ringに最適ですが、MODの場合は常に手動選択ボタンを使用して正しいMODランチャーを選択してください。

### 🛠️ トラブルシューティング
- **「セーブファイルが見つかりません」**: まずゲーム内でセーブを作成してください。
- **「バックアップ先が未設定です」**: 監視開始前にフォルダーを選択してください。
- **権限の問題**: インストーラーは管理者として実行してください。

---
## 🇫🇷 Français

> **📝 Note de traduction**: Cette traduction a été générée par des outils automatisés. De meilleures traductions peuvent être soumises sur GitHub.

### 🚀 Démarrage rapide

#### Installation
1. **Téléchargez** l'installateur `EldenRingSaveBackup.msi` depuis le dossier `dist`.
2. **Exécutez** l'installateur en tant qu'administrateur.
3. **Lancez** l'application depuis le menu Démarrer ou le raccourci du bureau.
4. **Configurez** l'emplacement de votre fichier de sauvegarde et les paramètres de sauvegarde.
5. **Démarrez** la surveillance pour créer automatiquement des sauvegardes.

#### Ce que fait l'application
- **Détecte automatiquement** les changements de votre fichier de sauvegarde Elden Ring.
- **Crée des sauvegardes compressées** (jusqu'à 90% plus petites).
- **Conserve plusieurs sauvegardes** avec nettoyage automatique des anciennes.
- **Compatible avec les mods** comme ModEngine2, Convergence et Seamless Coop.
- **Fonctionne en arrière-plan** avec une icône dans la zone de notification.

### 📁 Emplacements des sauvegardes
- **Elden Ring** : `%USERPROFILE%\\AppData\\Roaming\\EldenRing\\[SteamID]\\ER0000.sl2`
- **Seamless Coop** : `%USERPROFILE%\\AppData\\Roaming\\EldenRing\\[SteamID]\\ER0000.co2`

### 🎮 Utilisation de l'application

#### Configuration initiale
1. **Sélectionnez la langue** (6 langues disponibles).
2. **Configurez le fichier de sauvegarde** :
   - **Détection automatique** : Cliquez sur le bouton 🔍 à côté de "Browse" pour trouver automatiquement votre fichier de sauvegarde
   - **Navigation manuelle** : Cliquez sur "Browse" pour sélectionner manuellement votre fichier `ER0000.sl2` ou `ER0000.co2`
   - **Sauvegardes multiples** : Si vous avez plusieurs comptes Steam, la détection automatique affichera une boîte de dialogue de sélection
3. **Configurez l'exécutable du jeu** (Optionnel) :
   - **Détection automatique** : Cliquez sur le bouton 🔍 pour trouver automatiquement votre installation d'Elden Ring
   - **Navigation manuelle** : Cliquez sur "Browse" pour sélectionner manuellement votre exécutable de jeu ou lanceur de mods
   - **Pour les mods** : Utilisez la navigation manuelle pour sélectionner les lanceurs de mods comme ModEngine2
4. **Sélectionnez le dossier de sauvegardes** (recommandé : Documents).
5. **Ajustez la rétention** (nombre maximum, méthode et intervalle).
6. **Cliquez sur "Start Monitoring"** pour commencer.

#### 🔍 Boutons de détection automatique
L'application inclut des boutons intelligents de détection automatique (🔍) qui peuvent trouver automatiquement vos fichiers :

##### **Détection automatique des fichiers de sauvegarde**
- **Scanne automatiquement** les fichiers de sauvegarde d'Elden Ring dans les emplacements standard
- **Supporte plusieurs comptes Steam** - affiche une boîte de dialogue de sélection si plusieurs sont trouvés
- **Fonctionne avec les fichiers de sauvegarde vanilla d'Elden Ring** (format .sl2)
- **Survolez le bouton 🔍** pour les informations de tooltip

##### **Détection automatique de l'exécutable du jeu**
- **Scanne les chemins d'installation Steam courants** (lecteurs C:, D:, E:, F:)
- **Lit la configuration des bibliothèques Steam** depuis le registre et libraryfolders.vdf
- **Trouve les installations vanilla d'Elden Ring** automatiquement
- **Affiche une boîte de dialogue de sélection** si plusieurs installations sont trouvées

##### **Quand utiliser la navigation manuelle à la place**
- **Lanceurs de mods** : Utilisez toujours la navigation manuelle pour ModEngine2, Convergence, etc.
- **Installations personnalisées** : Emplacements de bibliothèque Steam non standard
- **Versions multiples du jeu** : Quand vous avez des installations à la fois vanilla et moddées
- **Emplacements de sauvegarde personnalisés** : Si vos sauvegardes sont dans des emplacements non standard

> **💡 Conseil** : La détection automatique fonctionne parfaitement pour Elden Ring vanilla, mais pour les mods, utilisez toujours le bouton de navigation manuelle pour vous assurer de sélectionner le bon lanceur de mods.

### 🛠️ Dépannage
- **"Fichier de sauvegarde introuvable"** : assurez-vous d'avoir créé une sauvegarde en jeu.
- **"Dossier de sauvegardes non configuré"** : sélectionnez un dossier avant de démarrer.
- **Autorisations** : exécutez l'installateur en tant qu'administrateur.

---

**Enjoy your Elden Ring adventures with peace of mind knowing your progress is safely backed up!** 🎮✨

---

## 🇪🇸 Español

> **📝 Nota de traducción**: Esta traducción fue generada por herramientas automatizadas. Se pueden enviar mejores traducciones en GitHub.

### 🚀 Inicio Rápido

#### Instalación
1. **Descarga** el instalador `EldenRingSaveBackup.msi` desde la carpeta `dist`.
2. **Ejecuta** el instalador como Administrador.
3. **Abre** la aplicación desde el Menú Inicio o el acceso directo del escritorio.
4. **Configura** la ubicación de tu archivo de guardado y los ajustes de copia de seguridad.
5. **Inicia** el monitoreo para crear copias de seguridad automáticamente.

#### Qué hace
- **Detecta automáticamente** cuándo cambia tu archivo de guardado de Elden Ring.
- **Crea copias comprimidas** (hasta un 90% más pequeñas).
- **Mantiene múltiples copias** y limpia automáticamente las antiguas.
- **Funciona con mods** como ModEngine2, Convergence y Seamless Coop.
- **Se ejecuta en segundo plano** con icono en la bandeja del sistema.

### 📁 Ubicaciones de guardado
- **Elden Ring**: `%USERPROFILE%\AppData\Roaming\EldenRing\[SteamID]\ER0000.sl2`
- **Seamless Coop**: `%USERPROFILE%\AppData\Roaming\EldenRing\[SteamID]\ER0000.co2`

### 🎮 Uso de la aplicación

#### Configuración inicial
1. **Selecciona el idioma** (6 idiomas disponibles).
2. **Configura el archivo de guardado**:
   - **Detección automática**: Haz clic en el botón 🔍 junto a "Browse" para encontrar automáticamente tu archivo de guardado
   - **Navegación manual**: Haz clic en "Browse" para seleccionar manualmente tu archivo `ER0000.sl2` o `ER0000.co2`
   - **Múltiples guardados**: Si tienes múltiples cuentas de Steam, la detección automática mostrará un diálogo de selección
3. **Configura el ejecutable del juego** (Opcional):
   - **Detección automática**: Haz clic en el botón 🔍 para encontrar automáticamente tu instalación de Elden Ring
   - **Navegación manual**: Haz clic en "Browse" para seleccionar manualmente tu ejecutable del juego o lanzador de mods
   - **Para mods**: Usa la navegación manual para seleccionar lanzadores de mods como ModEngine2
4. **Selecciona la carpeta de copias** (recomendado: Documentos).
5. **Ajusta la retención** (máximo de copias, método y temporizador).
6. **Pulsa "Start Monitoring"** para empezar.

#### 🔍 Botones de detección automática
La aplicación incluye botones inteligentes de detección automática (🔍) que pueden encontrar automáticamente tus archivos:

##### **Detección automática de archivos de guardado**
- **Escanea automáticamente** archivos de guardado de Elden Ring en ubicaciones estándar
- **Soporta múltiples cuentas de Steam** - muestra diálogo de selección si se encuentran múltiples
- **Funciona con archivos de guardado vanilla de Elden Ring** (formato .sl2)
- **Pasa el cursor sobre el botón 🔍** para información de tooltip

##### **Detección automática de ejecutable del juego**
- **Escanea rutas de instalación comunes de Steam** (unidades C:, D:, E:, F:)
- **Lee la configuración de bibliotecas de Steam** desde el registro y libraryfolders.vdf
- **Encuentra instalaciones vanilla de Elden Ring** automáticamente
- **Muestra diálogo de selección** si se encuentran múltiples instalaciones

##### **Cuándo usar navegación manual en su lugar**
- **Lanzadores de mods**: Siempre usa navegación manual para ModEngine2, Convergence, etc.
- **Instalaciones personalizadas**: Ubicaciones de biblioteca de Steam no estándar
- **Múltiples versiones del juego**: Cuando tienes instalaciones tanto vanilla como con mods
- **Ubicaciones de guardado personalizadas**: Si tus guardados están en ubicaciones no estándar

> **💡 Consejo**: La detección automática funciona genial para Elden Ring vanilla, pero para mods siempre usa el botón de navegación manual para asegurar que selecciones el lanzador de mods correcto.

### 🛠️ Solución de problemas
- **"Archivo de guardado no encontrado"**: asegúrate de tener creado un guardado.
- **"Carpeta de copias no configurada"**: selecciona una carpeta antes de iniciar.
- **Permisos**: ejecuta el instalador como Administrador.

---
