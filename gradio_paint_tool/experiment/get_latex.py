from pix2tex.cli import LatexOCR
from PIL import Image

image_path = "C:/Users/c4h4k/mypro/SciNotes/gradio_paint_tool/data/tex_text.png"
image = Image.open(image_path).convert('RGB')
ocr_model = LatexOCR()
latex_code = ocr_model(image)

print(latex_code)