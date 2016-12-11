class dataPlot {
  // by Douglas Mayhew 12/1/2016
  // Plots data and provides mouse sliding and zooming ability
  
  int dpXpos;
  int dpYpos;
  int dpWidth;
  int dpHeight;
  int dpDataLen;
  
  int wDataStartPos;    // the index of the first data point
  int wDataStopPos;     // the index of the last data point
  
  int outerPtrX = 0;    // outer loop pointer
  int innerPtrX = 0;    // inner loop pointer for convolution
  
  float pan_x;
  float scale_x;
  float pan_y;
  float scale_y;
  
  // phase correction drawing pointers
  float drawPtrX = 0;
  float drawPtrXLessK = 0;
  float drawPtrXLessKandD1 = 0;
  
  // =============================================================================================
  // Subpixel Variables
  int negPeakLoc;             // array index location of greatest negative peak value in 1st difference data
  int posPeakLoc;             // array index location of greatest positive peak value in 1st difference data
  double negPeakVal;          // value of greatest negative peak in 1st difference data, y axis (height centric)
  double posPeakVal;          // value of greatest positivefloat( peak in 1st difference data, y axis (height centric)
  double a1, b1, c1;          // sub pixel quadratic interpolation input variables for negative difference peak
  double a2, b2, c2;          // sub pixel quadratic interpolation input variables for positive difference peak
  double negPeakSubPixelLoc;  // quadratic interpolated negative peak subpixel x position; 
  double posPeakSubPixelLoc;  // quadratic interpolated positive peak subpixel x position
  double preciseWidth;        // filament width output in pixels
  double preciseWidthMM;      // filament width output in mm
  double precisePosition;     // center position output in pixels
  double preciseMMPos;        // canter position output in mm
  double roughWidth;          // integer difference between the two peaks without subpixel precision
  double shiftSumX;           // temporary variable for summing x shift values
  double XCoord;              // temporary variable for holding a screen X coordinate
  float  YCoord;              // temporary variable for holding a screen Y coordinate
  // =============================================================================================
  
  Legend Legend1;             // One Legend object, lists the colors and what they represent
  Grid Grid1;                 // One Grid object, draws a grid
  PanZoomX PZX1;              // pan/zoom object, integer-based for speed
  
  dataPlot (PApplet p, int plotXpos, int plotYpos, int plotWidth, int plotHeight, int plotDataLen) {
    
    dpXpos = plotXpos;
    dpYpos = plotYpos;
    dpWidth = plotWidth;
    dpHeight = plotHeight;
    dpDataLen = plotDataLen;
  
    PZX1 = new PanZoomX(p);   // Create PanZoom object
    pan_x = PZX1.getPanX();   // initial pan and zoom values
    scale_x = PZX1.getScaleX();
    pan_y = PZX1.getPanY();
    scale_y = PZX1.getScaleY();
    
    // create the Legend object, which lists the colors and what they represent
    Legend1 = new Legend(); 
      
    // create the Grid object, which draws a grid
    Grid1 = new Grid(); 
  }
  
  boolean over() {
    if (mouseX > 0 && mouseX < dpWidth && 
      mouseY > 0 && mouseY < SCREEN_HEIGHT + 40) {
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
    
    // update the local pan and scale variables from the PanZoom object which maintains them
    pan_x = PZX1.getPanX();
    scale_x = PZX1.getScaleX();
    pan_y = PZX1.getPanY();
    scale_y = PZX1.getScaleY();


    // The minimum number of input data samples is two times the kernel length, (we ignore 
    // the fist and last kernel lengths of data) + 1, which would result in the minumum of only one sample 
    // processed. 
    
    wDataStartPos = 0;
    wDataStopPos = dpDataLen;
    
    //wDataStartIndex = constrain(wDataStartIndex, 0, wDataLen);
    //wDataStopIndex = constrain(wDataStopIndex, 0, wDataLen);
    
    // draw grid, legend, and kernel
    //Grid1.drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 32/scale_x, int(pan_x));
    
    //drawGrid2(pan_x, (wDataLen * scale_x) + pan_x, 0, height + pan_y, 64 * scale_x, 256 * scale_y);
    
    Legend1.drawLegend();
    drawKernel(0, scale_x, 0, kernelMultiplier);
    
    if (signalSource == 3){             // Plot using Serial Data
      processSerialData();  // from 0 to SENSOR_PIXELS-1              
    } else
    {                                 // Plot using Simulated Data
      processData();        // from 0 to SENSOR_PIXELS-1
    }
    
    calculateSensorShadowPosition(); // Subpixel calculation  
    
    text("Use mouse to drag, mouse wheel to zoom", HALF_SCREEN_WIDTH-150, 90);
    
    text("pan_x: " + String.format("%.3f", pan_x) + 
    "  scale_x: " + String.format("%.3f", scale_x), 
    50, 50);
  }
  
  void drawKernel(float pan_x, float scale_x, float pan_y, float scale_y){
    
    // plot kernel data point
    stroke(COLOR_KERNEL_DATA);
    
    for (outerPtrX = 0; outerPtrX < KERNEL_LENGTH; outerPtrX++) { 
      // shift outerPtrX left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
      drawPtrXLessK = ((outerPtrX - HALF_KERNEL_LENGTH) * scale_x) + pan_x; 
  
      // draw new kernel point (y scaled up by kernelMultiplier for better visibility)
      point(drawPtrXLessK+HALF_SCREEN_WIDTH, 
      SCREEN_HEIGHT-kernelDrawYOffset - (kernel[outerPtrX] * scale_y) + pan_y);
     }
  }

  void processSerialData(){
  
    int outerCount = 0;
    
    // increment the outer loop pointer from 0 to SENSOR_PIXELS-1
    for (outerPtrX = wDataStartPos; outerPtrX < wDataStopPos; outerPtrX++) {
    
      outerCount++; // lets us index (x axis) on the screen offset from outerPtrX
      
      // receive serial port data into the input[] array:
      // Read a pair of bytes from the byte array, convert them into an integer, 
      // shift right 2 places(divide by 4), and copy result into data_Array[]
      input[outerPtrX] = (byteArray[outerPtrX<<1]<< 8 | (byteArray[(outerPtrX<<1) + 1] & 0xFF))>>2;
      
      // Below we prepare 3 indexes to phase shift the x axis to the left as drawn, which corrects 
      // for convolution shift, and then multiply by the x scaling variable, and add the pan_x variable.
      
      // the outer pointer to the screen X axis (l)
      drawPtrX = (outerCount * scale_x) + pan_x;
    
      // shift left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
      drawPtrXLessK = ((outerCount - HALF_KERNEL_LENGTH) * scale_x) + pan_x; 
      
      // shift left by half the kernel length and,
      // shift left by half a data point increment to properly position the 1st difference points in-beween the original data points.
      drawPtrXLessKandD1 = ((outerCount - HALF_KERNEL_LENGTH -0.5) * scale_x) + pan_x;
 
      // plot original data point
      stroke(COLOR_ORIGINAL_DATA);
      
      point(drawPtrX, HALF_SCREEN_HEIGHT - (input[outerPtrX] * scale_y) + pan_y);
      // draw section of greyscale bar showing the 'color' of original data values
      greyscaleBarMapped(drawPtrX, scale_x, 0, input[outerPtrX]);
    
      // convolution inner loop
      for (int innerPtrX = 0; innerPtrX < KERNEL_LENGTH; innerPtrX++) { // increment the inner loop pointer
        // convolution (that magic line which can do so many different things depending on the kernel)
        output[outerPtrX+innerPtrX] = output[outerPtrX+innerPtrX] + input[outerPtrX] * kernel[innerPtrX]; 
      }
  
      // plot the output data
      stroke(COLOR_OUTPUT_DATA);
      point(drawPtrXLessK, HALF_SCREEN_HEIGHT - (output[outerPtrX] * scale_y) + pan_y);
      //println("output[" + outerPtrX + "]" +output[outerPtrX]);
     
      // draw section of greyscale bar showing the 'color' of output data values
      greyscaleBarMapped(drawPtrXLessK, scale_x, 11, output[outerPtrX]);
      
      // find 1st difference of the convolved data, the difference between adjacent points in the input[] array.
      // We skip the first KERNEL_LENGTH of convolution output data, which is garbage from smoothing convolution 
      // kernel not being fully immersed in the input signal data.
     if (outerPtrX > KERNEL_LENGTH_MINUS1) {
        output2[outerPtrX] = output[outerPtrX] - output[outerPtrX-1]; // the difference between adjacent points, called the 1st difference
        stroke(COLOR_FIRST_DIFFERENCE_OF_OUTPUT);
        point(drawPtrXLessKandD1, HALF_SCREEN_HEIGHT - (output2[outerPtrX] * scale_y) + pan_y);
        // draw section of greyscale bar showing the 'color' of output2 data values
        //void greyscaleBarMapped(float x, float scale_x, float y, float value) {
        greyscaleBarMappedAbs(drawPtrXLessKandD1, scale_x, 22, output2[outerPtrX]);
      }
    }
  }
  
  void processData(){
    
    int outerCount = 0;
    
    // increment the outer loop pointer from 0 to SENSOR_PIXELS-1
    for (outerPtrX = wDataStartPos; outerPtrX < wDataStopPos; outerPtrX++) {
    
      outerCount++; // lets us index (x axis) on the screen offset from outerPtrX
      
      // Below we prepare 3 indexes to phase shift the x axis to the left as drawn, which corrects 
      // for convolution shift, and then multiply by the x scaling variable, and add the pan_x variable.
      
      // the outer pointer to the screen X axis (l)
      drawPtrX = (outerCount * scale_x) + pan_x;
    
      // shift left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
      drawPtrXLessK = ((outerCount - HALF_KERNEL_LENGTH) * scale_x) + pan_x; 
      
      // shift left by half the kernel length and,
      // shift left by half a data point increment to properly position the 1st difference points in-beween the original data points.
      drawPtrXLessKandD1 = ((outerCount - HALF_KERNEL_LENGTH -0.5) * scale_x) + pan_x;
 
      // plot original data point
      stroke(COLOR_ORIGINAL_DATA);
      
      point(drawPtrX, HALF_SCREEN_HEIGHT - (input[outerPtrX] * scale_y) + pan_y);
      // draw section of greyscale bar showing the 'color' of original data values
      greyscaleBarMapped(drawPtrX, scale_x, 0, input[outerPtrX]);
    
      // convolution inner loop
      for (int innerPtrX = 0; innerPtrX < KERNEL_LENGTH; innerPtrX++) { // increment the inner loop pointer
        // convolution (that magic line which can do so many different things depending on the kernel)
        output[outerPtrX+innerPtrX] = output[outerPtrX+innerPtrX] + input[outerPtrX] * kernel[innerPtrX]; 
      }
  
      // plot the output data
      stroke(COLOR_OUTPUT_DATA);
      point(drawPtrXLessK, HALF_SCREEN_HEIGHT - (output[outerPtrX] * scale_y) + pan_y);
      //println("output[" + outerPtrX + "]" +output[outerPtrX]);
     
      // draw section of greyscale bar showing the 'color' of output data values
      greyscaleBarMapped(drawPtrXLessK, scale_x, 11, output[outerPtrX]);
      
      // find 1st difference of the convolved data, the difference between adjacent points in the input[] array.
      // We skip the first KERNEL_LENGTH of convolution output data, which is garbage from smoothing convolution 
      // kernel not being fully immersed in the input signal data.
     if (outerPtrX > KERNEL_LENGTH_MINUS1) {
        output2[outerPtrX] = output[outerPtrX] - output[outerPtrX-1]; // the difference between adjacent points, called the 1st difference
        stroke(COLOR_FIRST_DIFFERENCE_OF_OUTPUT);
        point(drawPtrXLessKandD1, HALF_SCREEN_HEIGHT - (output2[outerPtrX] * scale_y) + pan_y);
        // draw section of greyscale bar showing the 'color' of output2 data values
        //void greyscaleBarMapped(float x, float scale_x, float y, float value) {
        greyscaleBarMappedAbs(drawPtrXLessKandD1, scale_x, 22, output2[outerPtrX]);
      }
    }
  }
  
  void greyscaleBarMapped(float x, float scale_X, float y, float value) {
    
    // prepare color to correspond to sensor pixel reading
    int bColor = int(map(value, 0, HIGHEST_ADC_VALUE, 0, 255));
  
    // Plot a row of pixels near the top of the screen ,
    // and color them with the 0 to 255 greyscale sensor value
    
    noStroke();
    fill(bColor, bColor, bColor);
    rect(x, y, scale_X, 10);
  }
  
  void greyscaleBarMappedAbs(float x, float scale_X, float y, float value) {
    
    // prepare color to correspond to sensor pixel reading
    int bColor = int(abs(map(value, 0, HIGHEST_ADC_VALUE, 0, 255)));
    // Plot a row of pixels near the top of the screen , //<>//
    // and color them with the 0 to 255 greyscale sensor value
    
    noStroke();
    fill(bColor, bColor, bColor);
    rect(x, y, scale_X, 10);
  }
  
  void calculateSensorShadowPosition(){
    
    // sub-pixel edge detection using interpolation
    // from Accelerated Image Processing blog, posting: Sub-Pixel Maximum
    // https://visionexperts.blogspot.com/2009/03/sub-pixel-maximum.html
    
    // the subpixel location of a shadow edge is found as the peak of a parabola fitted to 
    // the top 3 points of a smoothed original data's first difference peak.
    
    // the first difference is simply the difference between adjacent data 
    // points of the original data, ie, 1st difference = x[i] - x[i-1], for each i.
    
    // Each difference value is proportional to the steepness and direction of the slope in the 
    // original data at the location.
    // Also in this case we smooth the original data first to make the peaks we are searching for
    // more symmectrical and rounded, and thus closer to the shape of a parabola, which we fit to 
    // the peaks next. The more the highest (or lowest for negative peaks) 3 points of the peaks 
    // resemble a parabola, the more accurate the subpixel result.
      
    negPeakLoc = wDataStopPos; // one past the last pixel, to prevent false positives?
    posPeakLoc = wDataStopPos; // one past the last pixel, to prevent false positives?
    
    negPeakVal = 0;
    posPeakVal = 0;
    preciseWidth = 0;
    precisePosition = 0;
    
    //clear the sub-pixel buffers
    a1 = b1 = c1 = a2 = b2 = c2 = 0;
    
    negPeakSubPixelLoc = 0;
    posPeakSubPixelLoc = 0;
    
    // we should have already ran a gaussian smoothing routine over the data, and 
    // also already saved the 1st difference of the smoothed data into an array.
    // Therefore, all we do here is find the peaks on the 1st difference data.

    for (int i = wDataStartPos; i < wDataStopPos; i++) {
    // find the the tallest positive and negative peaks in 1st difference of the convolution output data, 
    // which is the point of steepest positive and negative slope in the smoothed original data.
      if (output2[i] > posPeakVal) {
        posPeakVal = output2[i];
        posPeakLoc = i;
      }else if (output2[i] < negPeakVal) {
        negPeakVal = output2[i];
        negPeakLoc = i;
      }
    }

    // store the 1st difference values to simple variables
    c1=output2[negPeakLoc+1];  // tallest negative peak array index location plus 1
    b1=output2[negPeakLoc];    // tallest negative peak array index location
    a1=output2[negPeakLoc-1];  // tallest negative peak array index location minus 1

    c2=output2[posPeakLoc+1];  // tallest positive peak array index location plus 1
    b2=output2[posPeakLoc];    // tallest positive peak array index location
    a2=output2[posPeakLoc-1];  // tallest positive peak array index location minus 1

    if (negPeakVal<-64 && posPeakVal>64) // check for significant threshold
    {
      roughWidth=posPeakLoc-negPeakLoc;
    } else 
    {
      roughWidth=0;
    }

    // check for width out of range (15.7pixels per mm, 65535/635=103)
    if(roughWidth > 8 && roughWidth < 103) {
      // for the subpixel value of the greatest negative peak found above, 
      // corresponds with the left edge of a narrow shadow cast upon the sensor
      negPeakSubPixelLoc = 0.5 * (a1 - c1) / (a1 - 2 * b1 + c1);
      
      // for the subpixel value of the greatest positive peak found above, 
      // corresponds with the right edge of a narrow shadow cast upon the sensor
      posPeakSubPixelLoc = 0.5 * (a2 - c2) / (a2 - 2 * b2 + c2);

      // original function translated from flipper's filament width sensor; does the same math calculation as above
      // negPeakSubPixelLoc=((a1-c1) / (a1+c1-(b1*2)))/2;
      // posPeakSubPixelLoc=((a2-c2) / (a2+c2-(b2*2)))/2;

      preciseWidth = roughWidth + (posPeakSubPixelLoc - negPeakSubPixelLoc); 
      preciseWidthMM = preciseWidth * sensorPixelSpacing;

      // solve for the center position
      precisePosition = (((negPeakLoc + negPeakSubPixelLoc) + (posPeakLoc + posPeakSubPixelLoc)) / 2);
      
      preciseMMPos = precisePosition * sensorPixelSpacing;

       // sum of a few offsets, so we don't need to recalculate
      shiftSumX =  0.5 + HALF_KERNEL_LENGTH - 1; 

      // Mark negPeakSubPixelLoc with red line
      noFill();
      strokeWeight(1);
      stroke(255, 0, 0);
      XCoord = ((negPeakLoc + negPeakSubPixelLoc - shiftSumX) * scale_x) + pan_x;
      line((float) XCoord, HALF_SCREEN_HEIGHT + subpixelMarkerLen, (float) XCoord, HALF_SCREEN_HEIGHT - subpixelMarkerLen);
 
      // Mark posPeakSubPixelLoc with green line
      stroke(0, 255, 0);
      XCoord = ((posPeakLoc + posPeakSubPixelLoc - shiftSumX) * scale_x) + pan_x;
      line((float) XCoord, HALF_SCREEN_HEIGHT + subpixelMarkerLen, (float) XCoord, HALF_SCREEN_HEIGHT - subpixelMarkerLen);

      // Mark subpixel center with white line
      stroke(255);
      XCoord = ((precisePosition - shiftSumX) * scale_x) + pan_x;
      line((float) XCoord, HALF_SCREEN_HEIGHT + subpixelMarkerLen, (float) XCoord, HALF_SCREEN_HEIGHT - subpixelMarkerLen); 

      // Mark negPeakLoc 3 pixel cluster with one red circle each
      stroke(255, 0, 0);
      ellipse((float) ((negPeakLoc - shiftSumX - 1) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (a1 * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((negPeakLoc - shiftSumX) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (b1 * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((negPeakLoc - shiftSumX + 1) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (c1 * scale_y) + pan_y), markSize, markSize);

      // Mark posPeakLoc 3 pixel cluster with one green circle each
      stroke(0, 255, 0);
      ellipse((float) ((posPeakLoc - shiftSumX - 1) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (a2 * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((posPeakLoc - shiftSumX) * scale_x) + pan_x,  (float) (HALF_SCREEN_HEIGHT - (b2 * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((posPeakLoc - shiftSumX + 1) * scale_x) + pan_x,  (float) (HALF_SCREEN_HEIGHT - (c2 * scale_y) + pan_y), markSize, markSize);
      
      YCoord = SCREEN_HEIGHT-120;
      fill(255);
      textSize(14);
      //text("negPeakLoc: " + negPeakLoc, 0, YCoord);
      //text("posPeakLoc: " + posPeakLoc, 125, YCoord);
      //text("negPeakSubPixelLoc: " + String.format("%.3f", negPeakSubPixelLoc), 250, YCoord);
      //text("posPeakSubPixelLoc: " + String.format("%.3f", posPeakSubPixelLoc), 325, YCoord);
      text("Pixel Width: " + String.format("%.3f", preciseWidth), 150, YCoord);
      text("Pixel Position = " + String.format("%.3f", precisePosition), 325, YCoord);
      text("Width mm: " + String.format("%.5f", preciseWidthMM), 525, YCoord);
      text("Center Position mm: " + String.format("%.5f", preciseMMPos), 675, YCoord);
    }
  }
}