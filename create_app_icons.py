import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_master_finish_icon(size=1024):
    scale = 2
    canvas_size = size * scale
    img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

    center = canvas_size / 2.0
    margin = canvas_size * 0.045
    rect_box = [margin, margin, canvas_size - margin, canvas_size - margin]
    corner_radius = canvas_size * 0.225

    # 1. Background Rounded Squircle with Rich Multilayer Gradient
    bg_gradient = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg_gradient)

    step = 4
    for y in range(0, canvas_size, step):
        for x in range(0, canvas_size, step):
            # Diagonal gradient angle (top-left to bottom-right)
            t = ((x * 0.6 + y * 1.0) / (canvas_size * 1.6))
            t = max(0.0, min(1.0, t))
            
            # Radial highlight at upper-left
            dx = (x - canvas_size * 0.35) / canvas_size
            dy = (y - canvas_size * 0.25) / canvas_size
            dist = math.sqrt(dx * dx + dy * dy)
            glow = max(0.0, 1.0 - dist * 1.8) * 0.4

            # Base gradient: Lush deep emerald (#0F4A3C) -> midnight emerald (#03211A)
            r = int((15 * (1 - t) + 3 * t) + glow * 45)
            g = int((105 * (1 - t) + 33 * t) + glow * 125)
            b = int((82 * (1 - t) + 26 * t) + glow * 95)
            
            r = min(255, max(0, r))
            g = min(255, max(0, g))
            b = min(255, max(0, b))
            
            bg_draw.rectangle([x, y, x + step, y + step], fill=(r, g, b, 255))

    # Mask background into squircle
    mask = Image.new("L", (canvas_size, canvas_size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(rect_box, radius=corner_radius, fill=255)

    img.paste(bg_gradient, (0, 0), mask)

    # 2. Ambient Inner Rim Highlight (Glass-edge look)
    rim_img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    rim_draw = ImageDraw.Draw(rim_img)
    rim_box = [margin + 3 * scale, margin + 3 * scale, canvas_size - margin - 3 * scale, canvas_size - margin - 3 * scale]
    rim_draw.rounded_rectangle(rim_box, radius=corner_radius - 3 * scale, outline=(255, 255, 255, 55), width=int(3.5 * scale))
    img = Image.alpha_composite(img, rim_img)

    # 3. Top Specular Sheen (Curved lighting reflection)
    top_sheen = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    ts_draw = ImageDraw.Draw(top_sheen)
    ts_draw.ellipse([margin + 40 * scale, margin + 10 * scale, canvas_size - margin - 40 * scale, margin + 300 * scale], fill=(255, 255, 255, 22))
    top_sheen = top_sheen.filter(ImageFilter.GaussianBlur(25 * scale))
    img = Image.alpha_composite(img, top_sheen)

    # 4. 3D Cast Shadow for the Emblem
    shadow_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)

    cx = center
    cy = center + 12 * scale

    # Checkmark polygon points
    p_left = (cx - 210 * scale, cy - 25 * scale)
    p_bottom = (cx - 65 * scale, cy + 155 * scale)
    p_top_right = (cx + 220 * scale, cy - 190 * scale)
    p_top_corner = (cx + 220 * scale, cy - 90 * scale)
    p_inner_bottom = (cx - 55 * scale, cy + 55 * scale)
    p_inner_left = (cx - 145 * scale, cy - 25 * scale)

    # Ambient deep shadow underneath
    s_off_y = 38 * scale
    shadow_pts = [
        (p_left[0], p_left[1] + s_off_y),
        (p_bottom[0], p_bottom[1] + s_off_y),
        (p_top_corner[0], p_top_corner[1] + s_off_y),
        (p_top_right[0], p_top_right[1] + s_off_y),
        (p_inner_bottom[0], p_inner_bottom[1] + s_off_y),
        (p_inner_left[0], p_inner_left[1] + s_off_y),
    ]
    shadow_draw.polygon(shadow_pts, fill=(0, 12, 9, 180))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(22 * scale))
    img = Image.alpha_composite(img, shadow_layer)

    # 5. 3D Bevel / Extrusion Edge (Dark metallic emerald depth)
    bevel_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    bevel_draw = ImageDraw.Draw(bevel_layer)
    ext_y = 20 * scale

    ext_pts_left = [
        p_left,
        p_bottom,
        (p_bottom[0], p_bottom[1] + ext_y),
        (p_left[0], p_left[1] + ext_y)
    ]
    ext_pts_right = [
        p_bottom,
        p_top_corner,
        (p_top_corner[0], p_top_corner[1] + ext_y),
        (p_bottom[0], p_bottom[1] + ext_y)
    ]
    bevel_draw.polygon(ext_pts_left, fill=(4, 95, 72, 255))
    bevel_draw.polygon(ext_pts_right, fill=(3, 72, 54, 255))
    img = Image.alpha_composite(img, bevel_layer)

    # 6. Main 3D Faceted Emblem (Vibrant Electric Mint & Emerald)
    emblem_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    emb_draw = ImageDraw.Draw(emblem_layer)

    # Left Stem Facet (#10B981)
    facet_left = [p_left, p_bottom, p_inner_bottom, p_inner_left]
    # Right Long Wing Facet (#34D399)
    facet_right = [p_inner_bottom, p_bottom, p_top_corner, p_top_right]

    emb_draw.polygon(facet_left, fill=(16, 185, 129, 255))
    emb_draw.polygon(facet_right, fill=(52, 211, 153, 255))

    # Top Light Reflection Sheen on Right Wing
    sheen_pts = [
        p_top_right,
        (cx + 85 * scale, cy - 45 * scale),
        (cx + 130 * scale, cy - 90 * scale),
        p_top_corner
    ]
    emb_draw.polygon(sheen_pts, fill=(110, 231, 183, 230))

    # 7. Secondary Dynamic Accent Layer (Floating 3D Amber Star/Diamond Accent)
    gem_cx = cx + 245 * scale
    gem_cy = cy - 220 * scale
    gem_r = 34 * scale

    # Diamond Shadow
    gem_shadow = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    gs_draw = ImageDraw.Draw(gem_shadow)
    gs_draw.ellipse([gem_cx - gem_r + 4*scale, gem_cy - gem_r + 14*scale, gem_cx + gem_r + 4*scale, gem_cy + gem_r + 14*scale], fill=(0, 15, 10, 150))
    gem_shadow = gem_shadow.filter(ImageFilter.GaussianBlur(8 * scale))
    img = Image.alpha_composite(img, gem_shadow)

    # Diamond Polygon in Warm Gold / Amber (#F59E0B / #FBBF24)
    diamond_pts = [
        (gem_cx, gem_cy - gem_r),
        (gem_cx + gem_r * 0.72, gem_cy),
        (gem_cx, gem_cy + gem_r),
        (gem_cx - gem_r * 0.72, gem_cy)
    ]
    emb_draw.polygon(diamond_pts, fill=(245, 158, 11, 255))

    diamond_sheen = [
        (gem_cx, gem_cy - gem_r),
        (gem_cx + gem_r * 0.72, gem_cy),
        (gem_cx, gem_cy)
    ]
    emb_draw.polygon(diamond_sheen, fill=(253, 230, 138, 255))
    emb_draw.ellipse([gem_cx - 6 * scale, gem_cy - 6 * scale, gem_cx + 6 * scale, gem_cy + 6 * scale], fill=(255, 255, 255, 240))

    # Precision Vector Border Line for crispness
    emb_draw.line([p_left, p_bottom, p_top_corner, p_top_right, p_inner_bottom, p_inner_left, p_left], fill=(255, 255, 255, 100), width=int(2.5 * scale))

    # Specular Gleams
    apex = p_top_right
    emb_draw.ellipse([apex[0] - 8*scale, apex[1] - 8*scale, apex[0] + 8*scale, apex[1] + 8*scale], fill=(255, 255, 255, 250))
    bot_apex = p_bottom
    emb_draw.ellipse([bot_apex[0] - 6*scale, bot_apex[1] - 6*scale, bot_apex[0] + 6*scale, bot_apex[1] + 6*scale], fill=(255, 255, 255, 200))

    img = Image.alpha_composite(img, emblem_layer)

    # Downsample to master size with high-quality Lanczos resampling
    final_master = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_master

def main():
    base_dir = r"c:\Users\dell\Desktop\Finish\mobile"
    
    # 1. Generate Master 1024x1024 Icon
    print("Rendering 1024x1024 master icon...")
    master = create_master_finish_icon(1024)
    
    # Assets directory
    assets_icon_dir = os.path.join(base_dir, "assets", "icons")
    os.makedirs(assets_icon_dir, exist_ok=True)
    master_path = os.path.join(assets_icon_dir, "app_icon.png")
    master.save(master_path, "PNG", quality=100)
    print(f"Saved master icon: {master_path}")

    # 2. Android Mipmap Icons
    res_dir = os.path.join(base_dir, "android", "app", "src", "main", "res")
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }

    for folder, px in densities.items():
        folder_path = os.path.join(res_dir, folder)
        os.makedirs(folder_path, exist_ok=True)
        icon_img = master.resize((px, px), Image.Resampling.LANCZOS)
        icon_path = os.path.join(folder_path, "ic_launcher.png")
        icon_img.save(icon_path, "PNG", quality=100)
        print(f"Saved Android icon {folder} ({px}x{px}): {icon_path}")

    # 3. Web Favicon & PWA Icons
    web_dir = os.path.join(base_dir, "web")
    web_icons_dir = os.path.join(web_dir, "icons")
    os.makedirs(web_icons_dir, exist_ok=True)

    # Favicon
    favicon = master.resize((32, 32), Image.Resampling.LANCZOS)
    favicon_path = os.path.join(web_dir, "favicon.png")
    favicon.save(favicon_path, "PNG")
    print(f"Saved favicon (32x32): {favicon_path}")

    # PWA Icons
    web_icons = {
        "Icon-192.png": 192,
        "Icon-512.png": 512,
        "Icon-maskable-192.png": 192,
        "Icon-maskable-512.png": 512,
    }
    for filename, px in web_icons.items():
        pwa_icon = master.resize((px, px), Image.Resampling.LANCZOS)
        pwa_path = os.path.join(web_icons_dir, filename)
        pwa_icon.save(pwa_path, "PNG", quality=100)
        print(f"Saved Web icon ({px}x{px}): {pwa_path}")

    print("\nSUCCESS: All launcher icons, master icons, and web favicons generated with premium handcrafted 3D finish aesthetic!")

if __name__ == "__main__":
    main()
