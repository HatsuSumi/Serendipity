#!/usr/bin/env pwsh
# count_lines.ps1
# 统计 Serendipity 项目所有源码文件的非空行数，按行数降序输出
# 包含注释行（注释也是开发者写的，有意义）
# 排除自动生成目录：.dart_tool, build, .flutter-plugins, generated, .git 等

$rootDir = $PSScriptRoot

# 排除的目录名（精确匹配路径片段）
$excludeDirs = @(
    '\.git',
    '\.dart_tool',
    '\build',
    '\.flutter-plugins',
    '\.idea',
    '\generated',
    '\.symlinks',
    '\windows\runner',
    '\android',
    '\ios',
    '\linux',
    '\macos',
    '\web',
    '\node_modules'
)

# 统计的文件扩展名
$extensions = @('.dart', '.ts', '.js', '.tsx', '.jsx', '.py', '.md', '.yaml', '.yml', '.json')

function ShouldExclude($path) {
    foreach ($pattern in $excludeDirs) {
        if ($path -match [regex]::Escape($pattern) -or $path -replace '/', '\' -match [regex]::Escape($pattern)) {
            return $true
        }
    }
    return $false
}

function CountNonEmptyLines($filePath) {
    try {
        $lines = Get-Content $filePath -ErrorAction Stop
        return ($lines | Where-Object { $_.Trim() -ne '' }).Count
    } catch {
        return 0
    }
}

Write-Host "正在扫描 $rootDir ..."
Write-Host ""

$results = @()

Get-ChildItem -Path $rootDir -Recurse -File | ForEach-Object {
    $file = $_
    $relativePath = $file.FullName.Substring($rootDir.Length).TrimStart('\', '/')

    # 跳过排除目录
    if (ShouldExclude $file.FullName) { return }

    # 只处理指定扩展名
    if ($extensions -notcontains $file.Extension.ToLower()) { return }

    $count = CountNonEmptyLines $file.FullName
    if ($count -gt 0) {
        $results += [PSCustomObject]@{
            Lines    = $count
            FilePath = $relativePath
        }
    }
}

# 按行数降序排列
$sorted = $results | Sort-Object -Property Lines -Descending

# 输出结果
$sorted | Format-Table -AutoSize @{
    Label      = '非空行数'
    Expression = { $_.Lines }
    Width      = 8
    Alignment  = 'Right'
}, @{
    Label      = '文件路径'
    Expression = { $_.FilePath }
}

# 汇总
$total = ($results | Measure-Object -Property Lines -Sum).Sum
$fileCount = $results.Count
Write-Host "─────────────────────────────────────────"
Write-Host "共 $fileCount 个文件，总非空行数：$total"
Write-Host ""
Write-Host "建议拆分阈值（非空行数）："
Write-Host "  Page 文件   > 400 行"
Write-Host "  Widget 组件 > 150 行"
Write-Host "  Provider    > 200 行"
Write-Host "  其他        > 300 行"

