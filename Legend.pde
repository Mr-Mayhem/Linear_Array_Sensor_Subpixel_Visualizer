class Legend {
  // by Douglas Mayhew 12/1/2016
  // This class draws the legend
  int textSizePlus2;
  
  Legend (int textSize) {
      textSizePlus2 = textSize + 2;
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

    rectY += textSizePlus2;
    stroke(COLOR_KERNEL_DATA);
    fill(COLOR_KERNEL_DATA);
    rect(rectX, rectY, rectWidth, rectHeight);
    fill(255);
    text("Convolution kernel", rectX + 20, rectY + 10);

    rectY += textSizePlus2;
    stroke(COLOR_OUTPUT_DATA);
    fill(COLOR_OUTPUT_DATA);
    rect(rectX, rectY, rectWidth, rectHeight);
    fill(255);
    text("Smoothed convolution output data", rectX + 20, rectY + 10);

    rectY += textSizePlus2;
    stroke(COLOR_FIRST_DIFFERENCE);
    fill(COLOR_FIRST_DIFFERENCE);
    rect(rectX, rectY, rectWidth, rectHeight);
    fill(255);
    text("1st difference of convolution output data", rectX + 20, rectY + 10);
  }
}