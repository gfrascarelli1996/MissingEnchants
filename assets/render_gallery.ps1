Add-Type -AssemblyName System.Drawing

# ============================================================================
# Shared helpers
# ============================================================================

function New-Bitmap([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    return $bmp
}

function New-Graphics($bmp) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    return $g
}

function Draw-RadialBackground($g, [int]$w, [int]$h, [double]$cx, [double]$cy,
                                [System.Drawing.Color]$center, [System.Drawing.Color]$edge) {
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $radius = [Math]::Max($w, $h)
    $path.AddEllipse(($cx - $radius), ($cy - $radius), ($radius * 2), ($radius * 2))
    $brush = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
    $brush.CenterPoint = New-Object System.Drawing.PointF([float]$cx, [float]$cy)
    $brush.CenterColor = $center
    $brush.SurroundColors = @($edge)
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()
    $path.Dispose()
}

function Draw-HexPattern($g, [int]$w, [int]$h, [int]$alpha) {
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha, 180, 140, 240), 1)
    $size = 42.0
    $hs = $size * [Math]::Sin([Math]::PI / 3.0)
    for ($y = 0; $y -lt ($h + $size); $y += ($size * 1.5)) {
        $offset = 0
        if ((([int]($y / ($size * 1.5))) % 2) -eq 1) { $offset = $hs }
        for ($x = -$size; $x -lt ($w + $size); $x += ($hs * 2)) {
            $cx = $x + $offset
            $cy = $y
            $pts = New-Object System.Drawing.PointF[] 6
            for ($i = 0; $i -lt 6; $i++) {
                $ang = [Math]::PI / 3.0 * $i + [Math]::PI / 6.0
                $pts[$i] = New-Object System.Drawing.PointF(
                    [float]($cx + $size / 2 * [Math]::Cos($ang)),
                    [float]($cy + $size / 2 * [Math]::Sin($ang)))
            }
            $g.DrawPolygon($pen, $pts)
        }
    }
    $pen.Dispose()
}

function Draw-Vignette($g, [int]$w, [int]$h) {
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $radius = [Math]::Max($w, $h)
    $path.AddEllipse(-($radius / 2), -($radius / 2), ($radius * 2), ($radius * 2))
    $brush = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
    $brush.CenterPoint = New-Object System.Drawing.PointF([float]($w / 2), [float]($h / 2))
    $brush.CenterColor = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
    $brush.SurroundColors = @([System.Drawing.Color]::FromArgb(210, 0, 0, 0))
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()
    $path.Dispose()
}

# ============================================================================
# Report-frame mockup renderer (draws the WoW dialog look)
# ============================================================================

function Draw-ReportFrame($g, [double]$x, [double]$y, [double]$w, [double]$h,
                          $rows, [string]$title, $subtitleSegments) {
    # Outer gold border (3-pass for gradient feel)
    $borderColors = @(
        [System.Drawing.Color]::FromArgb(255, 130, 90, 30),
        [System.Drawing.Color]::FromArgb(255, 218, 170, 60),
        [System.Drawing.Color]::FromArgb(255, 255, 220, 130)
    )
    for ($i = 0; $i -lt 3; $i++) {
        $pen = New-Object System.Drawing.Pen($borderColors[$i], (7 - $i * 2))
        $g.DrawRectangle($pen, [single]($x + $i), [single]($y + $i), [single]($w - 2 * $i), [single]($h - 2 * $i))
        $pen.Dispose()
    }

    # Inner background
    $inset = 5
    $innerRect = New-Object System.Drawing.RectangleF(
        [single]($x + $inset), [single]($y + $inset),
        [single]($w - $inset * 2), [single]($h - $inset * 2))
    $innerBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $innerRect,
        [System.Drawing.Color]::FromArgb(250, 18, 10, 30),
        [System.Drawing.Color]::FromArgb(250, 10, 6, 20),
        90.0)
    $g.FillRectangle($innerBrush, $innerRect)
    $innerBrush.Dispose()

    # Title bar
    $padX = 14
    $barY = $y + 12
    $barH = 44
    $barRect = New-Object System.Drawing.RectangleF(
        [single]($x + $padX), [single]$barY,
        [single]($w - $padX * 2), [single]$barH)
    $barBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $barRect,
        [System.Drawing.Color]::FromArgb(230, 62, 42, 12),
        [System.Drawing.Color]::FromArgb(230, 42, 26, 8),
        90.0)
    $g.FillRectangle($barBrush, $barRect)
    $barBrush.Dispose()

    # Title-bar sheen (top half)
    $sheenRect = New-Object System.Drawing.RectangleF(
        [single]($x + $padX), [single]$barY,
        [single]($w - $padX * 2), [single]($barH / 2))
    $sheenBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(28, 255, 220, 130))
    $g.FillRectangle($sheenBrush, $sheenRect)
    $sheenBrush.Dispose()

    # Title-bar edges (gold verticals)
    $edgePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(240, 245, 200, 90), 2)
    $g.DrawLine($edgePen, [single]($x + $padX), [single]$barY, [single]($x + $padX), [single]($barY + $barH))
    $g.DrawLine($edgePen, [single]($x + $w - $padX), [single]$barY, [single]($x + $w - $padX), [single]($barY + $barH))
    $edgePen.Dispose()

    # Title underline
    $underPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 210, 100), 3)
    $g.DrawLine($underPen, [single]($x + $padX), [single]($barY + $barH), [single]($x + $w - $padX), [single]($barY + $barH))
    $underPen.Dispose()

    # Title text (shadow + fill)
    $titleFont = New-Object System.Drawing.Font("Segoe UI Semibold", 20, [System.Drawing.FontStyle]::Bold)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $titleShadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 0, 0, 0))
    $g.DrawString($title, $titleFont, $titleShadow, (New-Object System.Drawing.RectangleF(
        [single]($x + $padX + 1), [single]($barY + 1),
        [single]($w - $padX * 2), [single]$barH)), $sf)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 210, 80))
    $g.DrawString($title, $titleFont, $titleBrush, (New-Object System.Drawing.RectangleF(
        [single]($x + $padX), [single]$barY,
        [single]($w - $padX * 2), [single]$barH)), $sf)
    $titleShadow.Dispose()
    $titleBrush.Dispose()
    $titleFont.Dispose()

    # Subtitle (colored segments, centered)
    $subFont = New-Object System.Drawing.Font("Segoe UI Semibold", 12, [System.Drawing.FontStyle]::Bold)
    $totalW = 0
    foreach ($seg in $subtitleSegments) {
        $sz = $g.MeasureString($seg.text, $subFont)
        $totalW += $sz.Width
    }
    $subY = $barY + $barH + 10
    $curX = $x + ($w - $totalW) / 2
    foreach ($seg in $subtitleSegments) {
        $br = New-Object System.Drawing.SolidBrush($seg.color)
        $g.DrawString($seg.text, $subFont, $br, [single]$curX, [single]$subY)
        $sz = $g.MeasureString($seg.text, $subFont)
        $curX += $sz.Width
        $br.Dispose()
    }
    $subFont.Dispose()

    # Rows
    $rowY = $barY + $barH + 40
    $rowH = 34
    $iconSize = 26
    $rowFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $tagFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

    foreach ($row in $rows) {
        $iconBgRect = New-Object System.Drawing.RectangleF(
            [single]($x + $padX + 4), [single]($rowY + ($rowH - $iconSize - 4) / 2),
            [single]($iconSize + 4), [single]($iconSize + 4))
        $iconBgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 0, 0, 0))
        $g.FillRectangle($iconBgBrush, $iconBgRect)
        $iconBgBrush.Dispose()

        # Icon: colored square with a small glyph
        if ($row.kind -eq "enchant") {
            $iconColor = [System.Drawing.Color]::FromArgb(255, 130, 40, 40)
            $glyphColor = [System.Drawing.Color]::FromArgb(255, 255, 180, 90)
        } else {
            $iconColor = [System.Drawing.Color]::FromArgb(255, 30, 60, 110)
            $glyphColor = [System.Drawing.Color]::FromArgb(255, 130, 200, 255)
        }
        $iconRect = New-Object System.Drawing.RectangleF(
            [single]($x + $padX + 6), [single]($rowY + ($rowH - $iconSize) / 2),
            [single]$iconSize, [single]$iconSize)
        $iconBrush = New-Object System.Drawing.SolidBrush($iconColor)
        $g.FillRectangle($iconBrush, $iconRect)
        $iconBrush.Dispose()

        # Draw a glyph inside icon
        if ($row.kind -eq "enchant") {
            # Swirl-like: two arcs
            $glyphPen = New-Object System.Drawing.Pen($glyphColor, 2)
            $g.DrawArc($glyphPen,
                [single]($iconRect.X + 5), [single]($iconRect.Y + 5),
                [single]($iconRect.Width - 10), [single]($iconRect.Height - 10),
                20, 220)
            $g.DrawArc($glyphPen,
                [single]($iconRect.X + 8), [single]($iconRect.Y + 8),
                [single]($iconRect.Width - 16), [single]($iconRect.Height - 16),
                200, 220)
            $glyphPen.Dispose()
        } else {
            # Diamond gem
            $gemPts = New-Object System.Drawing.PointF[] 4
            $cxIcon = $iconRect.X + $iconRect.Width / 2
            $cyIcon = $iconRect.Y + $iconRect.Height / 2
            $r = $iconRect.Width * 0.32
            $gemPts[0] = New-Object System.Drawing.PointF([single]$cxIcon, [single]($cyIcon - $r))
            $gemPts[1] = New-Object System.Drawing.PointF([single]($cxIcon + $r), [single]$cyIcon)
            $gemPts[2] = New-Object System.Drawing.PointF([single]$cxIcon, [single]($cyIcon + $r))
            $gemPts[3] = New-Object System.Drawing.PointF([single]($cxIcon - $r), [single]$cyIcon)
            $gemBrush = New-Object System.Drawing.SolidBrush($glyphColor)
            $g.FillPolygon($gemBrush, $gemPts)
            $gemBrush.Dispose()
        }

        # Slot label
        $labelRect = New-Object System.Drawing.RectangleF(
            [single]($x + $padX + $iconSize + 22), [single]$rowY,
            [single]($w - $padX * 2 - $iconSize - 130), [single]$rowH)
        $lsf = New-Object System.Drawing.StringFormat
        $lsf.Alignment = [System.Drawing.StringAlignment]::Near
        $lsf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $g.DrawString($row.slot, $rowFont, $labelBrush, $labelRect, $lsf)

        # Right-side tag
        if ($row.kind -eq "enchant") {
            $tagColor = [System.Drawing.Color]::FromArgb(255, 255, 92, 92)
            $tagText = "ENCHANT"
        } else {
            $tagColor = [System.Drawing.Color]::FromArgb(255, 102, 200, 255)
            if ($row.count -gt 1) { $tagText = "SOCKET x$($row.count)" } else { $tagText = "SOCKET" }
        }
        $tagBrush = New-Object System.Drawing.SolidBrush($tagColor)
        $tagRect = New-Object System.Drawing.RectangleF(
            [single]($x + $w - $padX - 130), [single]$rowY,
            [single]122, [single]$rowH)
        $rsf = New-Object System.Drawing.StringFormat
        $rsf.Alignment = [System.Drawing.StringAlignment]::Far
        $rsf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $g.DrawString($tagText, $tagFont, $tagBrush, $tagRect, $rsf)
        $tagBrush.Dispose()

        # Row divider
        $divPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(20, 255, 255, 255), 1)
        $g.DrawLine($divPen,
            [single]($x + $padX + 4), [single]($rowY + $rowH - 1),
            [single]($x + $w - $padX - 4), [single]($rowY + $rowH - 1))
        $divPen.Dispose()

        $rowY += $rowH
    }
    $rowFont.Dispose()
    $tagFont.Dispose()
    $labelBrush.Dispose()

    # OK button
    $btnW = 120
    $btnH = 30
    $btnX = $x + ($w - $btnW) / 2
    $btnY = $y + $h - $btnH - 14
    $btnRect = New-Object System.Drawing.RectangleF([single]$btnX, [single]$btnY, [single]$btnW, [single]$btnH)
    $btnBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $btnRect,
        [System.Drawing.Color]::FromArgb(255, 60, 40, 15),
        [System.Drawing.Color]::FromArgb(255, 32, 20, 6),
        90.0)
    $g.FillRectangle($btnBrush, $btnRect)
    $btnBrush.Dispose()
    $btnBorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 220, 175, 70), 2)
    $g.DrawRectangle($btnBorderPen, [single]$btnX, [single]$btnY, [single]$btnW, [single]$btnH)
    $btnBorderPen.Dispose()
    $okFont = New-Object System.Drawing.Font("Segoe UI Semibold", 12, [System.Drawing.FontStyle]::Bold)
    $okBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 225, 140))
    $g.DrawString("OK", $okFont, $okBrush, $btnRect, $sf)
    $okBrush.Dispose()
    $okFont.Dispose()
}

# ============================================================================
# Gallery 1: Report frame hero shot
# ============================================================================

function New-GalleryReport {
    param([string]$OutPath, [int]$Width = 1280, [int]$Height = 720)
    $bmp = New-Bitmap $Width $Height
    $g = New-Graphics $bmp

    Draw-RadialBackground $g $Width $Height ($Width * 0.55) ($Height * 0.45) `
        ([System.Drawing.Color]::FromArgb(255, 45, 28, 72)) `
        ([System.Drawing.Color]::FromArgb(255, 8, 4, 16))
    Draw-HexPattern $g $Width $Height 14
    Draw-Vignette $g $Width $Height

    $rows = @(
        @{ kind = "enchant"; slot = "Cloak" },
        @{ kind = "enchant"; slot = "Chest" },
        @{ kind = "enchant"; slot = "Wrist" },
        @{ kind = "enchant"; slot = "Hands" },
        @{ kind = "enchant"; slot = "Feet" },
        @{ kind = "enchant"; slot = "Ring 1" },
        @{ kind = "enchant"; slot = "Ring 2" },
        @{ kind = "socket"; slot = "Neck"; count = 1 },
        @{ kind = "socket"; slot = "Ring 1"; count = 1 },
        @{ kind = "socket"; slot = "Ring 2"; count = 1 }
    )

    $frameW = 460
    $frameH = 560
    $frameX = ($Width - $frameW) / 2 + 220
    $frameY = ($Height - $frameH) / 2

    # Soft glow behind frame
    for ($i = 6; $i -ge 0; $i--) {
        $glowRect = New-Object System.Drawing.RectangleF(
            [single]($frameX - 4 - $i * 6), [single]($frameY - 4 - $i * 6),
            [single]($frameW + 8 + $i * 12), [single]($frameH + 8 + $i * 12))
        $glowBrush = New-Object System.Drawing.SolidBrush(
            [System.Drawing.Color]::FromArgb((6 + $i), 255, 180, 60))
        $g.FillRectangle($glowBrush, $glowRect)
        $glowBrush.Dispose()
    }

    $subSegments = @(
        @{ text = "7 enchants";  color = [System.Drawing.Color]::FromArgb(255, 255, 94, 94) },
        @{ text = "   .   ";     color = [System.Drawing.Color]::FromArgb(255, 130, 130, 130) },
        @{ text = "3 sockets";   color = [System.Drawing.Color]::FromArgb(255, 102, 200, 255) },
        @{ text = "   missing";  color = [System.Drawing.Color]::FromArgb(255, 180, 180, 180) }
    )
    Draw-ReportFrame $g $frameX $frameY $frameW $frameH $rows "Missing Enchant" $subSegments

    # Left-side headline
    $headlineFont = New-Object System.Drawing.Font("Segoe UI", 42, [System.Drawing.FontStyle]::Bold)
    $subFont = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Regular)
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
    $goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 215, 120))
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 235, 235, 240))

    $headline1 = "Never pull"
    $headline2 = "unenchanted."
    $g.DrawString($headline1, $headlineFont, $shadowBrush, [single]82, [single]202)
    $g.DrawString($headline1, $headlineFont, $whiteBrush, [single]80, [single]200)
    $g.DrawString($headline2, $headlineFont, $shadowBrush, [single]82, [single]262)
    $g.DrawString($headline2, $headlineFont, $goldBrush, [single]80, [single]260)

    $subText = "A quick heads-up the moment you`nzone into a dungeon, raid, or M+."
    $g.DrawString($subText, $subFont, $whiteBrush, [single]80, [single]340)

    $tagFont = New-Object System.Drawing.Font("Segoe UI Semibold", 13, [System.Drawing.FontStyle]::Bold)
    $tagBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 180, 180, 180))
    $g.DrawString("/menc  .  auto-scan on instance entry", $tagFont, $tagBrush, [single]80, [single]428)

    $shadowBrush.Dispose(); $goldBrush.Dispose(); $whiteBrush.Dispose()
    $tagBrush.Dispose(); $headlineFont.Dispose(); $subFont.Dispose(); $tagFont.Dispose()

    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

# ============================================================================
# Gallery 2: Wide banner (icon + wordmark + tagline + mini frame)
# ============================================================================

function New-GalleryBanner {
    param([string]$OutPath, [int]$Width = 1920, [int]$Height = 480)
    $bmp = New-Bitmap $Width $Height
    $g = New-Graphics $bmp

    Draw-RadialBackground $g $Width $Height ($Width * 0.65) ($Height * 0.5) `
        ([System.Drawing.Color]::FromArgb(255, 50, 32, 82)) `
        ([System.Drawing.Color]::FromArgb(255, 6, 3, 14))
    Draw-HexPattern $g $Width $Height 12

    # Left wordmark
    $wordFont = New-Object System.Drawing.Font("Segoe UI Semibold", 84, [System.Drawing.FontStyle]::Bold)
    $tagFont = New-Object System.Drawing.Font("Segoe UI", 26, [System.Drawing.FontStyle]::Regular)
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 0, 0, 0))
    $goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 215, 120))
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 240, 240, 240))
    $g.DrawString("MissingEnchants", $wordFont, $shadowBrush, [single]122, [single]132)
    $g.DrawString("MissingEnchants", $wordFont, $goldBrush, [single]120, [single]130)
    $g.DrawString("Warns you the moment you zone in unenchanted.", $tagFont, $whiteBrush,
        [single]120, [single]260)
    $tagSmallFont = New-Object System.Drawing.Font("Segoe UI Semibold", 15, [System.Drawing.FontStyle]::Bold)
    $tagSmallBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 200, 200, 200))
    $g.DrawString("Retail  .  Midnight 12.0.7  .  Chat report + gold-bordered popup",
        $tagSmallFont, $tagSmallBrush, [single]120, [single]320)

    $wordFont.Dispose(); $tagFont.Dispose(); $tagSmallFont.Dispose()
    $shadowBrush.Dispose(); $goldBrush.Dispose(); $whiteBrush.Dispose(); $tagSmallBrush.Dispose()

    # Right: mini frame with 4 rows
    $rows = @(
        @{ kind = "enchant"; slot = "Cloak" },
        @{ kind = "enchant"; slot = "Wrist" },
        @{ kind = "socket"; slot = "Neck"; count = 1 },
        @{ kind = "socket"; slot = "Ring 1"; count = 1 }
    )
    $frameW = 460
    $frameH = 350
    $frameX = $Width - $frameW - 120
    $frameY = ($Height - $frameH) / 2
    for ($i = 6; $i -ge 0; $i--) {
        $glowRect = New-Object System.Drawing.RectangleF(
            [single]($frameX - $i * 6), [single]($frameY - $i * 6),
            [single]($frameW + $i * 12), [single]($frameH + $i * 12))
        $glowBrush = New-Object System.Drawing.SolidBrush(
            [System.Drawing.Color]::FromArgb((6 + $i), 255, 180, 60))
        $g.FillRectangle($glowBrush, $glowRect)
        $glowBrush.Dispose()
    }
    $subSegments = @(
        @{ text = "2 enchants";  color = [System.Drawing.Color]::FromArgb(255, 255, 94, 94) },
        @{ text = "   .   ";     color = [System.Drawing.Color]::FromArgb(255, 130, 130, 130) },
        @{ text = "2 sockets";   color = [System.Drawing.Color]::FromArgb(255, 102, 200, 255) },
        @{ text = "   missing";  color = [System.Drawing.Color]::FromArgb(255, 180, 180, 180) }
    )
    Draw-ReportFrame $g $frameX $frameY $frameW $frameH $rows "Missing Enchant" $subSegments

    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

# ============================================================================
# Gallery 3: Chat-command output showcase
# ============================================================================

function New-GalleryChat {
    param([string]$OutPath, [int]$Width = 1280, [int]$Height = 720)
    $bmp = New-Bitmap $Width $Height
    $g = New-Graphics $bmp

    Draw-RadialBackground $g $Width $Height ($Width / 2) ($Height / 2) `
        ([System.Drawing.Color]::FromArgb(255, 35, 22, 60)) `
        ([System.Drawing.Color]::FromArgb(255, 6, 3, 12))
    Draw-HexPattern $g $Width $Height 12
    Draw-Vignette $g $Width $Height

    # Chat panel
    $panelW = 900
    $panelH = 460
    $panelX = ($Width - $panelW) / 2
    $panelY = ($Height - $panelH) / 2
    $panelRect = New-Object System.Drawing.RectangleF([single]$panelX, [single]$panelY, [single]$panelW, [single]$panelH)
    $panelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 0, 0, 0))
    $g.FillRectangle($panelBrush, $panelRect)
    $panelBrush.Dispose()
    $panelBorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 140, 100, 50), 2)
    $g.DrawRectangle($panelBorderPen, [single]$panelX, [single]$panelY, [single]$panelW, [single]$panelH)
    $panelBorderPen.Dispose()

    # Header stripe
    $stripeRect = New-Object System.Drawing.RectangleF([single]$panelX, [single]$panelY, [single]$panelW, [single]30)
    $stripeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 26, 18, 46))
    $g.FillRectangle($stripeBrush, $stripeRect)
    $stripeBrush.Dispose()
    $stripeFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Regular)
    $stripeText = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 200, 200, 200))
    $g.DrawString("General", $stripeFont, $stripeText, [single]($panelX + 14), [single]($panelY + 6))
    $stripeFont.Dispose(); $stripeText.Dispose()

    # Lines
    $lineFont = New-Object System.Drawing.Font("Consolas", 15, [System.Drawing.FontStyle]::Regular)
    $lineY = $panelY + 50
    $lineH = 26

    $lines = @(
        @{ text = "[MissingEnchants] 10 issue(s) found:"; color = [System.Drawing.Color]::FromArgb(255, 255, 130, 190) },
        @{ text = "  Missing enchant on Cloak      [Ephemeral Wrappings]"; color = [System.Drawing.Color]::FromArgb(255, 255, 90, 90) },
        @{ text = "  Missing enchant on Chest      [Chestpiece of the Void]"; color = [System.Drawing.Color]::FromArgb(255, 255, 90, 90) },
        @{ text = "  Missing enchant on Wrist      [Cursed Bindings]"; color = [System.Drawing.Color]::FromArgb(255, 255, 90, 90) },
        @{ text = "  Missing enchant on Hands      [Gloves of Silent Steps]"; color = [System.Drawing.Color]::FromArgb(255, 255, 90, 90) },
        @{ text = "  Missing enchant on Feet       [Sabatons of Ash]"; color = [System.Drawing.Color]::FromArgb(255, 255, 90, 90) },
        @{ text = "  Missing enchant on Ring 1     [Signet of the Deep]"; color = [System.Drawing.Color]::FromArgb(255, 255, 90, 90) },
        @{ text = "  Missing enchant on Ring 2     [Band of the Umbral Tide]"; color = [System.Drawing.Color]::FromArgb(255, 255, 90, 90) },
        @{ text = "  Empty socket x1 on Neck       [Amulet of the Spire]"; color = [System.Drawing.Color]::FromArgb(255, 255, 175, 70) },
        @{ text = "  Empty socket x1 on Ring 1     [Signet of the Deep]"; color = [System.Drawing.Color]::FromArgb(255, 255, 175, 70) },
        @{ text = "  Empty socket x1 on Ring 2     [Band of the Umbral Tide]"; color = [System.Drawing.Color]::FromArgb(255, 255, 175, 70) }
    )
    foreach ($ln in $lines) {
        $br = New-Object System.Drawing.SolidBrush($ln.color)
        $g.DrawString($ln.text, $lineFont, $br, [single]($panelX + 14), [single]$lineY)
        $br.Dispose()
        $lineY += $lineH
    }
    $lineFont.Dispose()

    # Caption
    $capFont = New-Object System.Drawing.Font("Segoe UI Semibold", 18, [System.Drawing.FontStyle]::Bold)
    $capBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 240, 240, 240))
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString("Type /menc anywhere for a manual scan.", $capFont, $capBrush,
        (New-Object System.Drawing.RectangleF([single]$panelX, [single]($panelY + $panelH + 20), [single]$panelW, [single]40)), $sf)
    $capFont.Dispose(); $capBrush.Dispose()

    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

# ============================================================================
# Run
# ============================================================================

$base = "C:\Sviluppo\WoW\MissingEnchants\assets"

New-GalleryReport -OutPath "$base\gallery_1_report.png" -Width 1280 -Height 720
New-GalleryBanner -OutPath "$base\gallery_2_banner.png" -Width 1920 -Height 480
New-GalleryChat   -OutPath "$base\gallery_3_chat.png"   -Width 1280 -Height 720

Write-Output "Gallery images written to $base"
Get-ChildItem "$base\gallery_*.png" | Select-Object Name, Length
