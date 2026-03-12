#!/usr/bin/env python3
"""
BMP → PNG 변환 스크립트
- 배경색(#859898)을 투명으로 처리
- 캐릭터 리소스용
"""
from PIL import Image
from pathlib import Path

# 설정
TRANSPARENT_COLOR = (0x85, 0x98, 0x98)  # #859898
INPUT_DIR = Path("assets/Inbox/Character")
OUTPUT_DIR = Path("assets/sprites/characters/player")

def convert_bmp_to_png(bmp_path: Path, output_path: Path) -> None:
    """BMP를 PNG로 변환하고 배경색을 투명 처리."""
    img = Image.open(bmp_path).convert("RGBA")
    pixels = img.load()
    
    width, height = img.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # 배경색과 일치하면 투명하게
            if (r, g, b) == TRANSPARENT_COLOR:
                pixels[x, y] = (r, g, b, 0)
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path, "PNG")
    print(f"변환 완료: {output_path}")

def main():
    # BMP 파일 찾기
    bmp_files = list(INPUT_DIR.glob("chr01_*.bmp"))
    
    if not bmp_files:
        print("변환할 BMP 파일이 없습니다.")
        return
    
    print(f"변환 대상: {len(bmp_files)}개 파일")
    
    for bmp_path in sorted(bmp_files):
        # 파일명 매핑 (chr01_body.bmp → body.png)
        layer_name = bmp_path.stem.replace("chr01_", "")
        output_path = OUTPUT_DIR / f"{layer_name}.png"
        convert_bmp_to_png(bmp_path, output_path)
    
    print("\n모든 변환 완료!")

if __name__ == "__main__":
    main()
