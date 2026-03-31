# Pages 中西文混排字型設定工具

一個輕量級的 macOS 自動化工具，為 Apple Pages 文件實現「中西文混排」格式化。

## ⚠️ Disclaimer

- This app is a cognitive automation product. Involved models include: GPT 5.4, Claude Opus 4.5. 
- We urge the avoidance of using this app. We are not responsible for any result. We do not promise anything.

## 功能特色

- 🎯 **自動識別** CJK 字元（漢字、全形標點）與西文（拉丁字母、數字）
- 🎨 **原生下拉選單** 選擇系統已安裝的字型
- ⚡ **批次處理** 連續中文區段，提升效能
- 🔔 **狀態通知** 透過 macOS 通知中心回報進度

## Requirements

- macOS 26 (Tahoe); theoretically supports 10.15+
- Apple Pages 14.4 - 15.1.1; theoretically supports similar versions
- Traditional Chinese literacy

## 使用方法

1. 開啟 **Apple Pages** 並打開包含中英文混合的文件
2. 雙擊執行 **Pages-MixedFont-Setter.app**
3. 在對話框中選擇：
   - **中文字型**（例如：黑體-繁）
   - **英文字型**（例如：Helvetica）
4. 點擊「**套用**」開始處理
5. 等待完成通知

## 技術細節

### Unicode 識別範圍

| 區段 | 範圍 |
|------|------|
| CJK 統一漢字 | U+4E00–U+9FFF |
| CJK 擴充 A | U+3400–U+4DBF |
| CJK 符號與標點 | U+3000–U+303F |
| 全形字元 | U+FF00–U+FFEF |
| CJK 擴充 B+ | U+20000–U+2FA1F |

### 處理邏輯

1. 套用英文字型到整份文件（作為基底）
2. 分析文字，識別連續的 CJK 區段
3. 批次套用中文字型到各 CJK 區段

### 限制

僅套用字型家族 (font family)，未支援指定的變體或字重。

## 版本歷史

- **v1.1.0** - 新增 NSAlert 下拉選單介面
- **v1.0.0** - 初始版本

## Contributions

This repo does not accept contributions. Fork it as you like but don't ever bother the author.
