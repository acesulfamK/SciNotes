from PIL import Image
from pathlib import Path
from pix2text import Pix2Text


image_path = "C:/Users/c4h4k/mypro/SciNotes/gradio_paint_tool/data/hand_text.png"
images = [Image.open(image_path)]

p2t = Pix2Text.from_config()
file_path = Path(__file__).parent
outs = p2t.recognize_formula(images, return_text=True, save_analysis_res=None)  # recognize pure formula images

print('outs for pure formula images', outs)
