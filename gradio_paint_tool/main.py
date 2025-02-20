import gradio as gr
import numpy as np
from PIL import Image, ImageFilter
import random
from pix2tex.cli import LatexOCR
from pix2text import Pix2Text

# Placeholder function for converting handwriting to LaTeX
def handwriting_to_latex(image_input):
    """
    Convert a handwritten mathematical expression to LaTeX format.

    Args:
        image (numpy array): The sketch from the Gradio ImageEditor.

    Returns:
        str: The LaTeX representation of the handwritten expression.
    """
    
    image = image_input["layers"][0]
    if image is None:
        return "No input detected"


    image_invert = 255 - image[:, :, 3]
    image_rgb = np.stack([image_invert, image_invert, image_invert], axis=-1)
    image_pil = Image.fromarray(image_rgb)

    p2t = Pix2Text.from_config()
    outs = p2t.recognize_formula([image_pil], return_text=True, save_analysis_res=None)  # recognize pure formula images
    
    #image_pil = Image.fromarray(image_rgb).convert('RGB')
    #ocr_model = LatexOCR()
    #latex_code = ocr_model(image_pil)

    output_str = "".join(*[out for out in outs])
    
    return f"$$\n{output_str}\n$$"  # Simulating output

# Gradio interface
with gr.Blocks() as demo:
    gr.Markdown("# Math Handwriting Recognition with Gradio ✍️ ➡️ 𝕋𝕖𝕏")
    
    with gr.Row():
        with gr.Column():
            gr.Markdown("## Refined LaTeX Expression")
            output_latex = gr.Markdown(value="")

        with gr.Column():
            gr.Markdown("## Handwritten Input")
            image_editor = gr.Sketchpad(label="Draw your math expression", width=400, height=200, type="numpy")
    
    convert_button = gr.Button("Convert to LaTeX")
    
    # Connect button click to function

    convert_button.click(handwriting_to_latex, inputs=image_editor, outputs=output_latex)

# Launch the Gradio app
demo.launch()