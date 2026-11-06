> **本 repo 沒有嘸蝦米字碼表，要自己去下載。**
>
> Windows 安裝包也不含嘸蝦米字碼表或嘸蝦米字典；請把你自己合法取得的
> `liu7.cin` 或 `boshiamy.lime` 放進 `data/`，雙擊 `install.bat` 會在本機 build 後安裝。

# PuffIME（泡芙輸入法）

Windows / Android 的**嘸蝦米輸入法**，用 Rime 打造。

- **嘸蝦米**：打一碼就列出所有候選字，常用字優先；每多打一碼就縮小。
- **注音**：打 `` ` `` 直接切注音，不用換輸入法。
- **英文**：直接打，候選列最後有原文；Enter 一定出英文。
- **順手功能**：`v` 快速選第 2 個、符號形狀、`/X` 符號選單、五款配色。

## Windows 安裝

1. 下載 [PuffIME-win64.zip](https://github.com/felixgugu/PuffIME/releases/latest/download/PuffIME-win64.zip)。
2. 下載你自己合法取得的 `liu7.cin`（或 `boshiamy.lime`）。
3. 解壓縮 `PuffIME-win64.zip`，把字碼表放進裡面的 `data\` 資料夾。
4. **雙擊 `install.bat`**。它會用你的字碼表在本機 build 字典，然後安裝。
5. 看到 `Done.` 就完成了。
6. 在輸入框按 **Ctrl + &#96;** 或 **F4**，選「泡芙輸入法」。

> 安裝程式會自動安裝小狼毫（需要網路）、備份原本的 Rime 設定，然後重新部署。
> 字碼表只留在你的電腦上，不會上傳；套件本身不含嘸蝦米字碼表或嘸蝦米字典。
> 如果 Windows 跳出「已保護您的電腦」：按「更多資訊」→「仍要執行」。
> 如果跳出「開啟檔案」警告：按「執行」。
> 如果防毒軟體誤擋 `make_dict.exe`：請允許執行，它只會讀你的字碼表並在本機產生字典。

安裝完如果語言列沒有小狼毫，到 `C:\Program Files\Rime\weasel-0.17.4\` 執行
`WeaselSetup.exe`，把它加入鍵盤。

## 怎麼打字

| 動作 | 說明 |
|---|---|
| 打嘸蝦米碼 | 例如 `a` → 對；空白上屏 |
| 選字 | 數字鍵 `1`–`0` |
| 翻頁 | `PageUp` / `PageDown` |
| 英文 | 直接打；候選列最後是原文，`Enter` 直接上屏 |
| 注音 | 先打 `` ` ``，再打注音，例如 `` `su3 `` → 你 |
| `v` | 有候選時，快速上屏第 2 個候選 |
| `Shift+Space` | 切換符號形狀（半形 → 自然 → 全形） |
| `CapsLock` | 英文模式（長英文用） |
| `,,fk` / `,,fl` | 忘記清單 / 上一次從注音上屏的字 |

### 前綴候選（這個最特別）

打一碼就會列出所有以這個碼開頭的字，依**常用度**排序；每多打一碼，候選就減少。

- `i` → 後、我、說、這、讓、話、請…
- `a` → 對、也、會、點、過…
- `aa` → 寸、丶、錢、鋪、鑫…

精確碼的候選一定排最前面（維持字碼表順序），後面才是依字頻排序的補全候選。
候選旁邊會顯示「打這個碼可以到它」的最短碼，例如 `a` 下的「或」顯示 `aqoe`。

## Android（Trime 同文輸入法）

Android 版**要先安裝 Trime（同文輸入法）**。目前不提供預編譯的字典，請用你自己的
字碼表在 Windows build 後再放到手機。

### 1. 手機先安裝 Trime

- 在 Google Play 搜尋「Trime 同文輸入法」，或到
  [Trime 的 GitHub Releases](https://github.com/osfans/trime/releases) 下載 APK。
- 安裝後到 Android 設定 → 系統 → 語言與輸入 → 螢幕鍵盤，啟用 Trime。

### 2. 在 Windows 產生 Trime 方案包

需要這個 repo 和 Python。

1. 下載這個 repo（GitHub → Code → Download ZIP，或 `git clone`）。
2. 把 `liu7.cin` 或 `boshiamy.lime` 放進 `data\`。
3. 執行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build_trime.ps1
```

4. 會產生 `release\PuffIME-trime.zip`。

### 3. 放到手機並部署

1. 把 `PuffIME-trime.zip` 傳到手機。
2. 解壓到 `Download/PuffIME`，檔案要**直接放在這個資料夾**，不要多一層。
3. 開 Trime：
   - 第一次啟動：選「選擇外部資料夾…」→ `Download/PuffIME`
   - 已設定過：設定 → 使用者資料夾 → 資料儲存模式 →
     **從外部存儲同步** → 選同一個資料夾
4. 回 Trime 按 **「部署」**。
5. 選「泡芙輸入法」。

### 4. 注音鍵

底部空白鍵左邊有 **「中文／注音」** 鍵：

- 按一下：切中文並換成 **ㄅㄆㄇ 注音鍵盤**
- 長按：切換中文／英文

注音上屏後會自動回嘸蝦米 QWERTY 鍵盤。詳細圖解與測試清單在
`platforms/android/trime/README.md`。

> 如果鍵盤看起來還是 Gboard（空白鍵寫 English），先到 Android 設定 →
> 系統 → 語言與輸入 → 螢幕鍵盤啟用 Trime，再用鍵盤切換鍵選 Trime。

## 注意

- 只支援 Windows 10/11 x64。
- Windows 套件不含嘸蝦米字碼表或嘸蝦米字典；第一次安裝會用你自己的字碼表在本機 build。
- 請不要把你 build 出來的字典再散布；字碼表請使用合法來源。
- 前綴候選是靜態字頻排序，不會學習個人選字。

## 免責聲明 (Disclaimer)

1. **版權聲明**：本專案為獨立開發之開源輸入法程式，**本專案原始碼及發布版本中均不包含、不內建、亦不散布任何未經授權之字碼對照表檔案**。
2. **商標宣告**：「嘸蝦米」及「Boshiamy」為行易有限公司之註冊商標。本專案（PuffIME）與行易有限公司無任何投資、授權或合作關係，文中所提及之商標名稱僅供相容格式與拆碼規格之客觀說明使用。
3. **使用者責任**：使用者需自行提供合法授權之參考碼表檔案（如自行購買正版軟體取得之對照檔或使用開源字碼檔）。

## 給開發者

build、測試、字碼表放法、設計說明都在 `docs/` 和 `tools/`。
