class Legend {
  // by Douglas Mayhew 12/1/2016
  // This class draws the legend
  
  Legend () {

  }
  
  void drawLegend() {
  
    int rectX, rectY, rectWidth, rectHeight;
    
    rectX = 10;
    rectY = 65;
    rectWidth = 10;
    rectHeight = 10;
   
    // draw a legend showing what each color represents
    strokeWeight(1);
    
    stroke(COLOR_ORIGINAL_DATA);
    fill(COLOR_ORIGINAL_DATA);
    rect(rectX, rectY, rectWidth, rectHeight);
    fill(255);
    text("Original input data", rectX + 20, rectY + 10);
    
    rectY += 20;
    stroke(COLOR_KERNEL_DATA);
    fill(COLOR_KERNEL_DATA);
    rect(rectX, rectY, rectWidth, rectHeight);
    fill(255);
    text("Convolution kernel", rectX + 20, rectY + 10);
    
     rectY += 20;
    stroke(COLOR_OUTPUT_DATA);
    fill(COLOR_OUTPUT_DATA);
    rect(rectX, rectY, rectWidth, rectHeight);
    fill(255);
    text("Smoothed convolution output data, shifted back into original phase", rectX + 20, rectY + 10);
    
    rectY += 20;
    stroke(COLOR_DERIVATIVE1_OF_OUTPUT);
    fill(COLOR_DERIVATIVE1_OF_OUTPUT);
    rect(rectX, rectY, rectWidth, rectHeight);
    fill(255);
    text("1st derivative of convolution output data", rectX + 20, rectY + 10);
  
  }
}