class dataPlot {
  // by Douglas Mayhew 12/1/2016
  // Plots data and provides mouse sliding and zooming ability
  
  int wWidth, wHeight;    // width and height of plot area
  int wXpos, wYpos;       // x and y position of plot area
  int wDataLen;           // length of data array, the X axis
  int wPlotWidth;         // X Width of the plotted data
  int wDataStartIndex;    // the index of the first data point
  int wDataStopIndex;     // the index of the last data point
  
  float pan_x;
  float scale_x;
  float pan_y;
  float scale_y;
  
  int outerPtrX = 0;                           // outer loop pointer
  int innerPtrX = 0;                           // inner loop pointer for convolution
  
  // phase correction drawing pointers
  float drawPtrX = 0;
  float drawPtrXLessK = 0;
  float drawPtrXLessKandD1 = 0;

  Legend Legend1;         // One Legend object, lists the colors and what they represent
  Grid Grid1;             // One Grid object, draws a grid
  SubPixel SP1;
  PanZoomX PZX1;          // pan/zoom object, integer-based for speed
  
  dataPlot (PApplet p, int xp, int yp, int ww, int wh, int datalen) {
    
    wWidth = ww;
    wHeight = wh;
    wXpos = xp;
    wYpos = yp;
    wDataLen = datalen;
    
    PZX1 = new PanZoomX(p, wWidth);
    pan_x = PZX1.getPanX();
    scale_x = PZX1.getScaleX();
    pan_y = PZX1.getPanY();
    scale_y = PZX1.getScaleY();
    
    // create the Legend object, which lists the colors and what they represent
    Legend1 = new Legend(); 
      
    // create the Grid object, which draws a grid
    Grid1 = new Grid(); 
    
    // create the SubPixel object, which determines a shadow position on the sensor with subpixel accuracy
    SP1 = new SubPixel();
  }
  
  boolean over() {
    if (mouseX > 0 && mouseX < wWidth && 
      mouseY > 0 && mouseY < wHeight + 40) {
      return true;
    } else {
      return false;
    }
  }

void keyPressed() {
  PZX1.keyPressed();
}

void mouseDragged() {
  if (over()){
    PZX1.mouseDragged();
  }
}

void mouseWheel(int step) {
  if (over()){
    PZX1.mouseWheel(step);
  }
}
  
  void display() {
    float pan_x = PZX1.getPanX();
    float scale_x = PZX1.getScaleX();
    float pan_y = PZX1.getPanY();
    float scale_y = PZX1.getScaleY();

    wDataStartIndex = 0;
    wDataStopIndex = wDataLen;
    
    wPlotWidth = wDataLen;
    
    wDataStartIndex = constrain(wDataStartIndex, 0, wDataLen);
    wDataStopIndex = constrain(wDataStopIndex, 0, wDataLen);
    
    // draw grid, legend, and kernel
    //Grid1.drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 64/SCALE_X);
    Legend1.drawLegend();
    drawKernel(0, scale_x, 0, kernelMultiplier);
    
    if (signalSource == 3){             // Plot using Serial Data
      drawHeadFromSerialData(pan_x, scale_x, pan_y, scale_y, wDataStartIndex, wDataStopIndex);       // from 0 to SENSOR_PIXELS-1              
    } else
    {                                 // Plot using Simulated Data
      drawHeadFromSimulatedData(pan_x, scale_x, pan_y, scale_y, wDataStartIndex, wDataStopIndex);    // from 0 to SENSOR_PIXELS-1
    }
    
    DrawTail(pan_x, scale_x, pan_y, scale_y, SENSOR_PIXELS, OUTPUT_DATA_LENGTH);  // from SENSOR_PIXELS to (SENSOR_PIXELS + KERNEL_LENGTH)-1
    SP1.calculateSensorShadowPosition(pan_x, scale_x, pan_y, scale_y, wDataStartIndex, wDataStopIndex); // Subpixel calculation  
    
    text("pan_x: " + String.format("%.3f", pan_x) + 
    "  scale_x: " + String.format("%.3f", scale_x) + 
    "  pan_y: " + String.format("%.3f", pan_y) + 
    "  scale_y: " + String.format("%.3f", scale_y), 
    HALF_SCREEN_WIDTH-200, 90);
  }
  
  void drawKernel(float pan_x, float scale_x, float pan_y, float scale_y){
    
    // plot kernel data point
    strokeWeight(2);
    stroke(COLOR_KERNEL_DATA);
    
    for (outerPtrX = 0; outerPtrX < KERNEL_LENGTH; outerPtrX++) { 
      // shift outerPtrX left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
      drawPtrXLessK = ((outerPtrX - HALF_KERNEL_LENGTH) * scale_x) + pan_x; 
  
      // draw new kernel point (y scaled up by kernelMultiplier for better visibility)
      point(drawPtrXLessK+HALF_SCREEN_WIDTH, 
      SCREEN_HEIGHT-kernelDrawYOffset-(kernel[outerPtrX] * scale_y) + pan_y);
     }
  }

  void drawHeadFromSerialData(float pan_x, float scale_x, float pan_y, float scale_y, int dataStartPos, int dataStopPos){
  
    int outerCount = 0;
  
    // increment the outer loop pointer from 0 to SENSOR_PIXELS-1
    for (outerPtrX = dataStartPos; outerPtrX < dataStopPos; outerPtrX++) {
    
      outerCount++; // lets us draw widthwise (x axis) on the screen, offset from the data array index
      
      // zero the output data, otherwise values accumulate  between frames, and indeed if you comment 
      // this out, the 1st derivative plot looks quite trippy on the screen.
      output[outerPtrX + KERNEL_LENGTH_MINUS1] = 0; 

      // receive serial port data into the input[] array
       
      // Read a pair of bytes from the byte array, convert them into an integer, 
      // shift right 2 places(divide by 4), and copy result into data_Array[]
      input[outerPtrX] = (byteArray[outerPtrX<<1]<< 8 | (byteArray[(outerPtrX<<1) + 1] & 0xFF))>>2;
      
      // Below we prepare 3 indexes to phase shift the x axis to the left as drawn, which corrects 
      // for convolution shift, and then multiply by the x scaling variable.
      
      // the outer pointer to the data arrays
      drawPtrX = (outerCount * scale_x) + pan_x;
    
      // shift left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
      drawPtrXLessK = ((outerCount - HALF_KERNEL_LENGTH) * scale_x) + pan_x; 
      
      // shift left by half the kernel length and,
      // shift left by half a data point increment to properly position the 1st derivative points in-beween the original data points.
      drawPtrXLessKandD1 = ((outerCount - HALF_KERNEL_LENGTH -0.5) * scale_x) + pan_x;
 
      // plot original data point
      strokeWeight(1);
      stroke(COLOR_ORIGINAL_DATA);
      
      point(drawPtrX, HALF_SCREEN_HEIGHT - (input[outerPtrX] * scale_y) + pan_y);
      // draw section of greyscale bar showing the 'color' of original data values
      greyscaleBarMapped(drawPtrX, scale_x, 0, input[outerPtrX]);
    
      // convolution inner loop
      for (int innerPtrX = 0; innerPtrX < KERNEL_LENGTH; innerPtrX++) { // increment the inner loop pointer
        // convolution (that magic line which can do so many different things depending on the kernel)
        output[outerPtrX+innerPtrX] = int(output[outerPtrX+innerPtrX] + input[outerPtrX] * kernel[innerPtrX]); 
      }
  
      // plot the output data
      stroke(COLOR_OUTPUT_DATA);
      point(drawPtrXLessK, HALF_SCREEN_HEIGHT - (output[outerPtrX] * scale_y) + pan_y);
      //println("output[" + outerPtrX + "]" +output[outerPtrX]);
     
      // draw section of greyscale bar showing the 'color' of output data values
      greyscaleBarMapped(drawPtrXLessK, scale_x, 11, output[outerPtrX]);
      
      // find 1st derivative of the convolved data, the difference between adjacent points in the input[] array
      if (outerPtrX > 0){
        stroke(COLOR_DERIVATIVE1_OF_OUTPUT);
        output2[outerPtrX] = output[outerPtrX] - output[outerPtrX-1]; // the difference between adjacent points, called the 1st derivative
        point(drawPtrXLessKandD1, HALF_SCREEN_HEIGHT - (output2[outerPtrX] * scale_y) + pan_y);
        // draw section of greyscale bar showing the 'color' of output2 data values
        //void greyscaleBarMapped(float x, float scale_x, float y, float value) {
        greyscaleBarMappedAbs(drawPtrXLessKandD1, scale_x, 22, output2[outerPtrX]);
      }
    }
  }
  
  void drawHeadFromSimulatedData(float pan_x, float scale_x, float pan_y, float scale_y, int dataStartPos, int dataStopPos){
    
  
    int outerCount = 0;
  
    // increment the outer loop pointer from 0 to SENSOR_PIXELS-1
    for (outerPtrX = dataStartPos; outerPtrX < dataStopPos; outerPtrX++) {
    
      outerCount++; // lets us draw widthwise (x axis) on the screen, offset from the data array index
      
      // zero the output data, otherwise values accumulate  between frames, and indeed if you comment 
      // this out, the 1st derivative plot looks quite trippy on the screen.
      output[outerPtrX + KERNEL_LENGTH_MINUS1] = 0; 
      
      // input[] array is already populated by signal generator
      
      // Below we prepare 3 indexes to phase shift the x axis to the left as drawn, which corrects 
      // for convolution shift, and then multiply by the x scaling variable.
      
      // the outer pointer to the data arrays
      drawPtrX = (outerCount * scale_x) + pan_x;
    
      // shift left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
      drawPtrXLessK = ((outerCount - HALF_KERNEL_LENGTH) * scale_x) + pan_x; 
      
      // shift left by half the kernel length and,
      // shift left by half a data point increment to properly position the 1st derivative points in-beween the original data points.
      drawPtrXLessKandD1 = ((outerCount - HALF_KERNEL_LENGTH -0.5) * scale_x) + pan_x;
 
      // plot original data point
      strokeWeight(1);
      stroke(COLOR_ORIGINAL_DATA);
      
      point(drawPtrX, HALF_SCREEN_HEIGHT - (input[outerPtrX] * scale_y) + pan_y);
      // draw section of greyscale bar showing the 'color' of original data values
      greyscaleBarMapped(drawPtrX, scale_x, 0, input[outerPtrX]);
    
      // convolution inner loop
      for (int innerPtrX = 0; innerPtrX < KERNEL_LENGTH; innerPtrX++) { // increment the inner loop pointer
        // convolution (that magic line which can do so many different things depending on the kernel)
        output[outerPtrX+innerPtrX] = int(output[outerPtrX+innerPtrX] + input[outerPtrX] * kernel[innerPtrX]); 
      }
  
      // plot the output data
      stroke(COLOR_OUTPUT_DATA);
      point(drawPtrXLessK, HALF_SCREEN_HEIGHT - (output[outerPtrX] * scale_y) + pan_y);
      //println("output[" + outerPtrX + "]" +output[outerPtrX]);
     
      // draw section of greyscale bar showing the 'color' of output data values
      greyscaleBarMapped(drawPtrXLessK, scale_x, 11, output[outerPtrX]);
    
      // find 1st derivative of the convolved data, the difference between adjacent points in the input[] array
      if (outerPtrX > 0){
        stroke(COLOR_DERIVATIVE1_OF_OUTPUT);
        output2[outerPtrX] = output[outerPtrX] - output[outerPtrX-1];
        point(drawPtrXLessKandD1, HALF_SCREEN_HEIGHT - (output2[outerPtrX] * scale_y) + pan_y);
        // draw section of greyscale bar showing the 'color' of output2 data values
        greyscaleBarMappedAbs(drawPtrXLessKandD1, scale_x, 22, output2[outerPtrX]);
      }
    }
  }

  void DrawTail(float pan_x, float scale_x, float pan_y, float scale_y, int dataStartPos, int dataStopPos){
    // this draws the last few pixels (half the kernel length) that exist in the convolution output array beyond 
    // the original pixel count as a result of convolution. Since typical useful kernels are only 9 pixels in 
    // length or so, we are talking only 4 pixels or so.
    // We can ignore these last few pixels by commenting out this code from firing. I seperated this for
    // sake of not needing to have guarding if statements for all pixels on the 'head' draw loop, which draws the 
    // bulk of the pixels.
    // This improves speed and efficiency by removing the overhead of some range-constraining if statements.
  
    // By the time you needed a kernel large enough where the pixels to be drawm at this step grew significant in number,
    // you would be smoothing the data so much the subpixel code would be losing a lot of accuracy, so the number of
    // skipped pixels at the end of the plot for which this function is responsible for drawing, 
    // is likely to remain insignificant. In fact, this comment is becoming larger than the function which it describes, 
    // so at this point you are probably thinking I should stop writing about now.
  
    int outerCount = SENSOR_PIXELS;
    
    // increment the outer loop pointer from SENSOR_PIXELS to (SENSOR_PIXELS + KERNEL_LENGTH)-1
    for (outerPtrX = dataStartPos; outerPtrX < dataStopPos; outerPtrX++) { 
      
      outerCount++;
      
      // no need to zero the output data here, apparently. It always gets overwritten, not accumulated.
      
      // println("output[" + outerPtrX + "]" +output[outerPtrX]);
      
      // the outer pointer to the data arrays
      drawPtrX = (outerCount * scale_x) + pan_x;
      
      // shift left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
      drawPtrXLessK = ((outerCount - HALF_KERNEL_LENGTH) * scale_x) + pan_x;
      
      // shift left by half the kernel length and,
      // shift left by half a data point increment for aligning all plots involving data of the 1st derivative 
      // (differences between data points are drawn in-between, or phase shifted to the left by 0.5 increments.
      // Note, this is a float to accomodate the fractional decimals. Processing accepts floats for screen coordinates,
      // but you don't see any difference compared to an integer until you spread the data points out from one
      // another on the screen in the X axis (the width related axis).
      drawPtrXLessKandD1 = ((outerCount - HALF_KERNEL_LENGTH -0.5) * scale_x) + pan_x;
      
      // plot the output data
      stroke(COLOR_TAIL);
      point(drawPtrXLessK, HALF_SCREEN_HEIGHT-(output[outerPtrX] * scale_y) + pan_y);
      
     
      // draw section of greyscale bar showing the 'color' of output data values
      greyscaleBarMapped(drawPtrXLessK, scale_x, 11, output[outerPtrX]);
    
      // find 1st derivative of the convolved data, the difference between adjacent points in the input[] array
      stroke(COLOR_DERIVATIVE1_OF_OUTPUT);
      output2[outerPtrX] = output[outerPtrX] - output[outerPtrX-1];
      point(drawPtrXLessKandD1, HALF_SCREEN_HEIGHT-(output2[outerPtrX] * scale_y) + pan_y);
      // draw section of greyscale bar showing the 'color' of output2 data values
      greyscaleBarMappedAbs(drawPtrXLessKandD1, scale_x, 22, output2[outerPtrX]);
    }
  }
  
  void greyscaleBarMapped(float x, float scale_x, float y, float value) {
    
    // prepare color to correspond to sensor pixel reading
    int bColor = int(map(value, 0, HIGHEST_ADC_VALUE, 0, 255));
  
    // Plot a row of pixels near the top of the screen ,
    // and color them with the 0 to 255 greyscale sensor value
    
    noStroke();
    fill(bColor, bColor, bColor);
    rect(x, y, scale_x, 10);
  }
  
  void greyscaleBarMappedAbs(float x, float scale_x, float y, float value) {
    
    // prepare color to correspond to sensor pixel reading
    int bColor = int(abs(map(value, 0, HIGHEST_ADC_VALUE, 0, 255)));
    // Plot a row of pixels near the top of the screen , //<>//
    // and color them with the 0 to 255 greyscale sensor value
    
    noStroke();
    fill(bColor, bColor, bColor);
    rect(x, y, scale_x, 10);
  }
}