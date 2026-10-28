param(
    [Parameter(Mandatory = $true)][string]$Tag,
    [Parameter(Mandatory = $true)][string]$ApkPath,
    [string]$Name = "",
    [string]$NotesFile = "",
    [string]$Notes = "",
    [string]$Token = $env:GH_TOKEN
)

$ErrorActionPreference = 'Stop'
$Owner = 'inpoortt-net'
$Repo = 'xiaolanjxiaoyuan'

if ([string]::IsNullOrWhiteSpace($Token)) {
    throw "缺少 GitHub Token：设置环境变量 GH_TOKEN，或传 -Token"
}
if (-not (Test-Path $ApkPath)) {
    throw "APK 不存在：$ApkPath"
}
if (-not [string]::IsNullOrWhiteSpace($NotesFile) -and (Test-Path $NotesFile)) {
    $Notes = Get-Content $NotesFile -Raw -Encoding UTF8
}
if ([string]::IsNullOrWhiteSpace($Name)) { $Name = "小蓝鲸 $Tag" }
if ([string]::IsNullOrWhiteSpace($Notes)) { $Notes = "见下个版本的更新说明。" }

$apk = Get-Item $ApkPath
$headers = @{
    'Authorization'        = "Bearer $Token"
    'Accept'               = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
    'User-Agent'           = 'xiaolanjing-release-script'
}

$payload = @{
    tag_name   = $Tag
    name       = $Name
    body       = $Notes
    draft      = $false
    prerelease = $false
} | ConvertTo-Json -Depth 5

Write-Host "创建 Release $Tag ..."
$release = Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$Owner/$Repo/releases" -Headers $headers -Body $payload -ContentType 'application/json'

$uploadUrl = ($release.upload_url -replace '\{\?name,label\}', '') + "?name=$([uri]::EscapeDataString($apk.Name))&label=$([uri]::EscapeDataString('小蓝鲸 ' + $Tag))"
Write-Host "上传 $($apk.Name) ($([math]::Round($apk.Length / 1MB, 1)) MB) ..."

$asset = Invoke-RestMethod -Method Post -Uri $uploadUrl -Headers $headers -InFile $apk.FullName -ContentType 'application/vnd.android.package-archive'

Write-Host ""
Write-Host "完成：$($release.html_url)"
Write-Host "资产：$($asset.browser_download_url)"
