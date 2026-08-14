from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
STORE_DIR = ROOT / "store_assets" / "google_play"


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255
    )
    return mask


def brand_background(size: tuple[int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size)
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            nx = (x - width * 0.5) / (width * 0.72)
            ny = (y - height * 0.42) / (height * 0.78)
            radial = max(0.0, 1.0 - (nx * nx + ny * ny) ** 0.5)
            vertical = y / max(1, height - 1)
            pixels[x, y] = (
                int(4 + 8 * radial),
                int(31 + 31 * radial - 7 * vertical),
                int(105 + 86 * radial - 14 * vertical),
            )
    return image


def render_app_icon(size: int = 1024) -> Image.Image:
    """Render a deterministic, geometric work-order icon without generated art."""
    scale = 2
    canvas_size = size * scale
    canvas = brand_background((canvas_size, canvas_size)).convert("RGBA")

    def box(values: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
        return tuple(value * scale for value in values)

    def point(values: tuple[int, int]) -> tuple[int, int]:
        return tuple(value * scale for value in values)

    # One restrained shadow system for the full card stack.
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        box((172, 236, 852, 856)), radius=78 * scale, fill=(0, 8, 42, 92)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(28 * scale))
    canvas = Image.alpha_composite(canvas, shadow)

    draw = ImageDraw.Draw(canvas)

    # Two balanced background cards communicate a work-order queue.
    draw.rounded_rectangle(
        box((126, 244, 666, 824)),
        radius=74 * scale,
        fill=(91, 83, 222, 255),
        outline=(119, 116, 240, 255),
        width=3 * scale,
    )
    draw.rounded_rectangle(
        box((358, 244, 898, 824)),
        radius=74 * scale,
        fill=(54, 104, 224, 255),
        outline=(88, 137, 237, 255),
        width=3 * scale,
    )

    # Main work order, with consistent geometry and minimal depth.
    front = box((218, 164, 806, 850))
    draw.rounded_rectangle(
        front,
        radius=74 * scale,
        fill=(249, 251, 255, 255),
        outline=(222, 229, 244, 255),
        width=4 * scale,
    )
    draw.rounded_rectangle(
        box((360, 164, 664, 264)),
        radius=34 * scale,
        fill=(40, 88, 201, 255),
    )
    draw.rectangle(box((360, 164, 664, 214)), fill=(40, 88, 201, 255))

    # Three deliberately simple checklist rows.
    row_colors = [(32, 191, 169, 255), (54, 112, 232, 255), (108, 99, 232, 255)]
    row_y = [360, 500, 640]
    row_widths = [278, 278, 188]
    for color, y, width in zip(row_colors, row_y, row_widths):
        draw.ellipse(box((302, y - 32, 366, y + 32)), fill=color)
        draw.rounded_rectangle(
            box((414, y - 18, 414 + width, y + 18)),
            radius=18 * scale,
            fill=(24, 43, 91, 255),
        )

    # Flat completion status: one circle, one check, no ornate seal.
    draw.ellipse(
        box((610, 648, 824, 862)),
        fill=(244, 183, 64, 255),
        outline=(255, 205, 96, 255),
        width=7 * scale,
    )
    draw.line(
        [point((662, 756)), point((706, 800)), point((776, 714))],
        fill=(255, 255, 255, 255),
        width=24 * scale,
        joint="curve",
    )

    return canvas.convert("RGB").resize((size, size), Image.Resampling.LANCZOS)


def save_rgb(image: Image.Image, path: Path, size: tuple[int, int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize(size, Image.Resampling.LANCZOS).convert("RGB").save(
        path, "PNG", optimize=True
    )


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    names = [
        "msyhbd.ttc" if bold else "msyh.ttc",
        "simhei.ttf" if bold else "simsun.ttc",
    ]
    for name in names:
        candidate = Path("C:/Windows/Fonts") / name
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size=size)
    return ImageFont.load_default(size=size)


def feature_graphic(master: Image.Image) -> Image.Image:
    canvas = brand_background((1024, 500))
    draw = ImageDraw.Draw(canvas, "RGBA")

    # Restrained workflow decoration behind the icon.
    for offset, alpha in [(0, 34), (28, 22), (56, 14)]:
        draw.rounded_rectangle(
            (650 + offset, 62 - offset // 4, 970 + offset, 438 + offset // 4),
            radius=48,
            fill=(106, 99, 232, alpha),
            outline=(255, 255, 255, alpha),
            width=2,
        )

    icon = master.resize((350, 350), Image.Resampling.LANCZOS)
    icon_mask = rounded_mask(icon.size, 78)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((630, 89, 994, 453), radius=86, fill=(0, 0, 0, 74))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)
    canvas.paste(icon, (637, 75), icon_mask)

    draw = ImageDraw.Draw(canvas, "RGBA")
    title_font = font(58, bold=True)
    subtitle_font = font(26)
    pill_font = font(20, bold=True)
    draw.text((64, 88), "维修工单助手", font=title_font, fill=(255, 255, 255, 255))
    draw.text(
        (66, 176),
        "接单、报价、维修、收款\n一张工单全程管理",
        font=subtitle_font,
        fill=(226, 234, 255, 238),
        spacing=12,
    )

    pills = [("离线可用", 66), ("流程清晰", 202), ("数据本地保存", 338)]
    for label, x in pills:
        bbox = draw.textbbox((0, 0), label, font=pill_font)
        width = bbox[2] - bbox[0] + 38
        draw.rounded_rectangle(
            (x, 315, x + width, 363),
            radius=24,
            fill=(23, 58, 150, 255),
            outline=(113, 178, 255, 255),
            width=1,
        )
        draw.text((x + 19, 324), label, font=pill_font, fill=(255, 255, 255, 242))

    return canvas.convert("RGB")


def main() -> None:
    master = render_app_icon(1024)

    # Project design sources.
    save_rgb(master, ROOT / "assets/icon/app_icon_design.png", (1254, 1254))
    save_rgb(master, ROOT / "assets/icon/app_icon.png", (1024, 1024))
    save_rgb(master, ROOT / "assets/icon/app_icon_foreground.png", (1024, 1024))

    # Google Play listing assets.
    save_rgb(master, STORE_DIR / "app-icon-512.png", (512, 512))
    feature = feature_graphic(master)
    save_rgb(feature, STORE_DIR / "feature-graphic-1024x500.png", (1024, 500))

    # Android legacy and round launcher icons.
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    android_res = ROOT / "android/app/src/main/res"
    for folder, size in android_sizes.items():
        save_rgb(master, android_res / folder / "ic_launcher.png", (size, size))
        save_rgb(master, android_res / folder / "ic_launcher_round.png", (size, size))
    save_rgb(
        master,
        android_res / "drawable-nodpi/ic_launcher_foreground.png",
        (1024, 1024),
    )

    # iOS AppIcon sizes declared by the existing asset catalog.
    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, size in ios_sizes.items():
        save_rgb(master, ios_dir / name, (size, size))


if __name__ == "__main__":
    main()
