Add-Type -AssemblyName System.Drawing

$folders = @{'mdpi'=48;'hdpi'=72;'xhdpi'=96;'xxhdpi'=144;'xxxhdpi'=192}

foreach ($folder in $folders.Keys) {
    $size = $folders[$folder]
    $bitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point(0, 0)),
        (New-Object System.Drawing.Point($size, $size)),
        [System.Drawing.Color]::FromArgb(255, 108, 99, 255),
        [System.Drawing.Color]::FromArgb(255, 138, 108, 255)
    )

    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
    $graphics.FillEllipse($brush, $rect)

    $moonBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $moonFont = New-Object System.Drawing.Font("Segoe UI Emoji", [int]($size * 0.5))
    $moonSize = $graphics.MeasureString("🌙", $moonFont)
    $moonX = ($size - $moonSize.Width) / 2
    $moonY = ($size - $moonSize.Height) / 2 - $size * 0.05
    $graphics.DrawString("🌙", $moonFont, $moonBrush, $moonX, $moonY)

    $bitmap.Save("mobile/android/app/src/main/res/mipmap-$folder/ic_launcher.png", [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Created mipmap-$folder icon: $size x $size"

    $graphics.Dispose()
    $bitmap.Dispose()
}
