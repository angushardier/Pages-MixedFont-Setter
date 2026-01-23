# Pages 中西文混排字型設定工具

一個輕量級的 macOS 自動化工具，為 Apple Pages 文件實現「中西文混排」格式化。

## 功能特色

- 🎯 **自動識別** CJK 字元（漢字、全形標點）與西文（拉丁字母、數字）
- 🎨 **原生下拉選單** 選擇系統已安裝的字型
- ⚡ **批次處理** 連續中文區段，提升效能
- 🔔 **狀態通知** 透過 macOS 通知中心回報進度

## 系統需求

- macOS 10.15 (Catalina) 或更新版本
- Apple Pages（iWork 14+）

## 安裝與編譯

### 使用預編譯版本

直接雙擊 `Pages-MixedFont-Setter.app` 即可使用。

### 從原始碼編譯

```bash
osacompile -o "Pages-MixedFont-Setter.app" "PagesMixedFontSetter.applescript"
```

## 使用方法

1. 開啟 **Apple Pages** 並打開包含中英文混合的文件
2. 雙擊執行 **Pages-MixedFont-Setter.app**
3. 在對話框中選擇：
   - **中文字型**（例如：宋體-簡、黑體-繁）
   - **英文字型**（例如：Times New Roman、Helvetica）
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

## 授權

MIT License

## 版本歷史

- **v1.2.1** - 修復中文字型未套用問題，改用批次處理
- **v1.1.0** - 新增 NSAlert 下拉選單介面
- **v1.0.0** - 初始版本
