Add-Type -AssemblyName System.Drawing

function New-MissingEnchantsIcon {
    param(
        [int]$Size = 512,
        [string]$OutPath
    )

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $cx = $Size / 2.0
    $cy = $Size / 2.0

    # --- 1) Radial background: deep magical purple -> near black at edges ---
    $bgRect = New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)
    $bgPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $bgPath.AddEllipse(-$Size, -$Size, $Size * 3, $Size * 3)
    $bgBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($bgPath)
    $bgBrush.CenterPoint = New-Object System.Drawing.PointF($cx, $cy)
    $bgBrush.CenterColor = [System.Drawing.Color]::FromArgb(255, 58, 31, 92)
    $bgBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(255, 10, 4, 20))
    $g.FillRectangle($bgBrush, $bgRect)
    $bgBrush.Dispose()
    $bgPath.Dispose()

    # --- 2) Outer glow ring (soft purple aura) ---
    for ($i = 0; $i -lt 6; $i++) {
        $r = $Size * (0.46 - $i * 0.015)
        $alpha = [int](18 - $i * 2.5)
        if ($alpha -lt 0) { $alpha = 0 }
        $glowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha, 180, 120, 255), 18)
        $g.DrawEllipse($glowPen, $cx - $r, $cy - $r, $r * 2, $r * 2)
        $glowPen.Dispose()
    }

    # --- 3) Hexagonal socket ---
    function Get-Hexagon([double]$cx, [double]$cy, [double]$radius, [double]$rotationDeg = 0) {
        $pts = New-Object System.Drawing.PointF[] 6
        for ($i = 0; $i -lt 6; $i++) {
            $angle = ([Math]::PI / 180.0) * (60.0 * $i + $rotationDeg)
            $pts[$i] = New-Object System.Drawing.PointF(
                [float]($cx + $radius * [Math]::Cos($angle)),
                [float]($cy + $radius * [Math]::Sin($angle))
            )
        }
        return ,$pts
    }

    $hexRadius = $Size * 0.32
    $hexPts = Get-Hexagon $cx $cy $hexRadius -90

    # 3a) Hex inner fill (very dark, simulates empty socket cavity)
    $hexPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $hexPath.AddPolygon($hexPts)
    $cavityBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($hexPath)
    $cavityBrush.CenterPoint = New-Object System.Drawing.PointF([float]$cx, [float]($cy - $Size * 0.05))
    $cavityBrush.CenterColor = [System.Drawing.Color]::FromArgb(255, 28, 14, 48)
    $cavityBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(255, 6, 2, 14))
    $g.FillPath($cavityBrush, $hexPath)
    $cavityBrush.Dispose()

    # 3b) Hex inner highlight ring (subtle inner edge sheen)
    $innerSheenPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 200, 180, 255), 3)
    $hexInnerPts = Get-Hexagon $cx $cy ($hexRadius * 0.85) -90
    $g.DrawPolygon($innerSheenPen, $hexInnerPts)
    $innerSheenPen.Dispose()

    # 3c) Hex outer border (gold, prominent)
    $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 245, 200, 80), 9)
    $borderPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawPolygon($borderPen, $hexPts)
    $borderPen.Dispose()

    # 3d) Hex outer highlight (white-ish top edges)
    $highlightPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 240, 200), 3)
    $highlightPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $hexHiPts = Get-Hexagon $cx ($cy - 2) ($hexRadius - 4) -90
    $g.DrawPolygon($highlightPen, $hexHiPts)
    $highlightPen.Dispose()
    $hexPath.Dispose()

    # --- 4) Sparkles around the socket (4 small 4-point stars) ---
    function Draw-Sparkle([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$size, [int]$alpha) {
        $pts = New-Object System.Drawing.PointF[] 8
        $long = $size
        $short = $size * 0.3
        $pts[0] = New-Object System.Drawing.PointF([float]$x, [float]($y - $long))
        $pts[1] = New-Object System.Drawing.PointF([float]($x + $short), [float]($y - $short))
        $pts[2] = New-Object System.Drawing.PointF([float]($x + $long), [float]$y)
        $pts[3] = New-Object System.Drawing.PointF([float]($x + $short), [float]($y + $short))
        $pts[4] = New-Object System.Drawing.PointF([float]$x, [float]($y + $long))
        $pts[5] = New-Object System.Drawing.PointF([float]($x - $short), [float]($y + $short))
        $pts[6] = New-Object System.Drawing.PointF([float]($x - $long), [float]$y)
        $pts[7] = New-Object System.Drawing.PointF([float]($x - $short), [float]($y - $short))
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 255, 240, 200))
        $g.FillPolygon($brush, $pts)
        $brush.Dispose()
    }

    Draw-Sparkle $g ($cx - $Size * 0.36) ($cy - $Size * 0.18) ($Size * 0.035) 230
    Draw-Sparkle $g ($cx + $Size * 0.34) ($cy - $Size * 0.22) ($Size * 0.025) 200
    Draw-Sparkle $g ($cx + $Size * 0.38) ($cy + $Size * 0.20) ($Size * 0.03)  220
    Draw-Sparkle $g ($cx - $Size * 0.32) ($cy + $Size * 0.24) ($Size * 0.022) 190

    # --- 5) Red "!" warning badge top-right ---
    $badgeR = $Size * 0.13
    $badgeCx = $Size * 0.78
    $badgeCy = $Size * 0.22

    # Soft red glow behind badge
    for ($i = 0; $i -lt 5; $i++) {
        $gr = $badgeR + $i * 6
        $a = 22 - $i * 4
        if ($a -lt 0) { $a = 0 }
        $gb = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, 255, 60, 60))
        $g.FillEllipse($gb, $badgeCx - $gr, $badgeCy - $gr, $gr * 2, $gr * 2)
        $gb.Dispose()
    }

    # Badge fill (radial red gradient)
    $badgePath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $badgePath.AddEllipse($badgeCx - $badgeR, $badgeCy - $badgeR, $badgeR * 2, $badgeR * 2)
    $badgeBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($badgePath)
    $badgeBrush.CenterPoint = New-Object System.Drawing.PointF([float]($badgeCx - $badgeR * 0.3), [float]($badgeCy - $badgeR * 0.3))
    $badgeBrush.CenterColor = [System.Drawing.Color]::FromArgb(255, 255, 120, 100)
    $badgeBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(255, 180, 25, 25))
    $g.FillPath($badgeBrush, $badgePath)
    $badgeBrush.Dispose()
    $badgePath.Dispose()

    # Badge border
    $badgeBorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 235, 220), 4)
    $g.DrawEllipse($badgeBorderPen, $badgeCx - $badgeR, $badgeCy - $badgeR, $badgeR * 2, $badgeR * 2)
    $badgeBorderPen.Dispose()

    # "!" — drawn as a rounded rectangle stem + dot
    $stemW = $badgeR * 0.30
    $stemH = $badgeR * 0.95
    $stemX = $badgeCx - $stemW / 2
    $stemY = $badgeCy - $badgeR * 0.62
    $exclBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 250, 245))

    # Stem
    $stemPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rr = $stemW * 0.5
    $stemPath.AddArc([single]$stemX, [single]$stemY, [single]$stemW, [single]$stemW, 180, 180)
    $stemPath.AddArc([single]$stemX, [single]($stemY + $stemH - $stemW), [single]$stemW, [single]$stemW, 0, 180)
    $stemPath.CloseFigure()
    $g.FillPath($exclBrush, $stemPath)
    $stemPath.Dispose()

    # Dot
    $dotR = $badgeR * 0.18
    $g.FillEllipse($exclBrush, $badgeCx - $dotR, $badgeCy + $badgeR * 0.45 - $dotR, $dotR * 2, $dotR * 2)
    $exclBrush.Dispose()

    # Save
    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $g.Dispose()
    $bmp.Dispose()
}

$base = "C:\Sviluppo\WoW\MissingEnchants\assets"
New-MissingEnchantsIcon -Size 512 -OutPath "$base\icon_512.png"
New-MissingEnchantsIcon -Size 256 -OutPath "$base\icon_256.png"
New-MissingEnchantsIcon -Size 128 -OutPath "$base\icon_128.png"
New-MissingEnchantsIcon -Size 64  -OutPath "$base\icon_64.png"

Write-Output "Icons written to $base"
Get-ChildItem "$base\icon_*.png" | Select-Object Name, Length
