# 发版流程

每次改完要发新版，走这三步。

## 1. 改版本号

`ChaoxingSignFaker/app/build.gradle`：

```groovy
defaultConfig {
    versionCode 119040069   // 每次发版 +1
    versionName "1.19.4-stable-261024"  // 前三位是给人看的版本号
}
```

App 里判断有没有新版，比的就是 `versionName` 前三段数字（`-stable-261024` 后缀会被忽略）。
所以 **`versionName` 的第一段数字必须真的变大**，例如 `1.19.4` → `1.19.5`。

## 2. 编译 release 包

```powershell
$env:JAVA_HOME = 'C:\Users\邓轶鑫\.local\jdk-21.0.12.1+1'
$env:ANDROID_HOME = 'C:\Users\邓轶鑫\AppData\Local\Android\Sdk'
$env:UMENG_CHANNEL = 'Stackbricks'
$env:KS_FILE = 'C:\Users\邓轶鑫\AppData\Local\Temp\fallback-release.jks'
$env:keystorePassword = '<keystore 密码>'

Set-Location 'C:\QT CREATOR\ChaoxingSignFaker'
& 'C:\Users\邓轶鑫\.local\gradle-9.7.1\bin\gradle.bat' :app:assembleRelease `
    --console=plain -I 'C:\Users\邓轶鑫\AppData\Local\Temp\app-build2.init.gradle'
```

产物：`app\build\outputs\apk\release\app-release.apk`

## 3. 推上 GitHub

先设 token（GitHub → Settings → Developer settings → Personal access tokens，勾 `repo` 权限）：

```powershell
$env:GH_TOKEN = 'ghp_xxxxxxxx'
```

然后一条命令建 Release 并上传 APK：

```powershell
.\scripts\publish-release.ps1 `
    -Tag 'v1.19.5' `
    -ApkPath 'C:\QT CREATOR\ChaoxingSignFaker\app\build\outputs\apk\release\app-release.apk' `
    -Notes '修了课表周次；排班链接支持勾选'
```

更新日志里写 `[force]` 或 `【强制更新】` → App 里会变成不能跳过的强制更新。

---

## 检查更新怎么拿数据

App 请求：

```
GET https://api.github.com/repos/inpoortt-net/xiaolanjxiaoyuan/releases/latest
```

- `tag_name` → 版本号（`v` 前缀会被去掉）
- `body` → 更新日志正文
- `assets[]` 里第一个 `.apk` 的 `browser_download_url` → 下载直链
- 没有 `.apk` 资产时回退到 `html_url`（Release 页面）

**仓库里没有任何 Release 时返回 404，App 侧当成「已是最新」处理，不会报错。**
