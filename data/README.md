# 字碼表放這裡

本專案**不包含**嘸蝦米字碼表。請自行取得合法來源的 `liu7.cin`（預設）或
`boshiamy.lime`，放到這個資料夾：

```
data/liu7.cin          # 預設
data/boshiamy.lime     # 選用
```

## Windows 安裝包

把字碼表放進 `data\` 後，雙擊 `install.bat`。安裝程式會用你的字碼表在本機
build 字典，然後安裝；字碼表不會上傳。

## 自行 build

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build.ps1
# 或
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build.ps1 -Source lime
```

`tools/build.ps1` 會在建置時顯示清楚錯誤，如果缺少字碼表。
