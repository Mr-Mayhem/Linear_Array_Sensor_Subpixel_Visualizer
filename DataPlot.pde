class dataPlot {
  // by Douglas Mayhew 12/1/2016
  // Plots data and provides mouse sliding and zooming ability
  
  int dpXpos;              // dataPlot class init variables
  int dpYpos;
  int dpWidth;
  int dpHeight;
  int dpDataLen;
  
  int input;              // a single convolution input y value
  float cOutPrev;         // the previous convolution output y value
  float cOut;             // the current convolution output y value
  
  
  float kernelMultiplier; // multiplies the plotted y values of the kernel, for greater visibility since they are small
  int kernelDrawYOffset;  // height above bottom of screen to draw the kernel data points

  int wDataStartPos;      // the index of the first data point
  int wDataStopPos;       // the index of the last data point
  
  int outerPtrX = 0;      // outer loop pointer
  int innerPtrX = 0;      // inner loop pointer for convolution
  
  float pan_x;            // local copies of variables from PanZoom object
  float scale_x;
  float pan_y;
  float scale_y;
  float dpKernelSigma;     // current kernel sigma as determined by kernel Pan Zoom object
  float dpPrevKernelSigma; // previous kernel sigma as determined by kernel Pan Zoom object
  float drawPtrX = 0;      // phase correction drawing pointers
  float drawPtrXLessK = 0;
  float drawPtrXLessKlessD1 = 0;
  // =============================================================================================
  // Subpixel Variables
  float negPeakLoc;           // x index position of greatest negative y difference peak found in 1st difference data
  float posPeakLoc;           // x index position of greatest positive y difference peak found in 1st difference data
  
  float widthInPixels;        // integer difference between the two peaks without subpixel precision
  
  double negPeakVal;          // value of greatest negative y difference peak found in 1st difference data
  double posPeakVal;          // value of greatest positive y difference peak found in 1st difference data 
  
  double negPeakLeftPixel;    // y value of left neighbor (x - 1) of greatest 1st difference negative peak
  double negPeakCenterPixel;  // y value of 1st difference (x) of greatest negative peak
  double negPeakRightPixel;   // y value of right neighbor (x + 1) of greatest 1st difference negative peak
  
  double posPeakLeftPixel;    // y value of left neighbor (x - 1) of greatest 1st difference positive peak
  double posPeakCenterPixel;  // y value of 1st difference (x) of greatest positive peak
  double posPeakRightPixel;   // y value of right neighbor (x + 1) of greatest 1st difference positive peak
  
  double negPeakSubPixelLoc;  // quadratic interpolated negative peak subpixel x position; 
  double posPeakSubPixelLoc;  // quadratic interpolated positive peak subpixel x position
  
  double preciseWidth;        // filament width output in pixels
  double preciseWidthLowPass; // width filtered with simple running average filter
  double preciseWidthMM;      // filament width output in mm
  
  double precisePosition;     // center position output in pixels
  double precisePositionLowPass; // position filtered with simple running average filter
  double preciseMMPos;        // canter position output in mm
  
  double shiftSumX;           // temporary variable for summing x shift values
  double calibrationCoefficient = 0.981; // corrects mm width by multiplying by this value
  
  float diff0, diff1, diff2;       // temp variables which hold derivative values, used instead of another array
  float  XCoord;              // temporary variable for holding a screen X coordinate
  float  YCoord;              // temporary variable for holding a screen Y coordinate
  
  int markSize;               // diameter of drawn subpixel marker circles
  int subpixelMarkerLen;      // length of vertical lines which indicate subpixel peaks and shadow center location
  
  // =============================================================================================
  //Arrays
  
  float[] output = new float[0];       // array for output signal
  
  // =============================================================================================
  
  Legend Legend1;            // One Legend object, lists the colors and what they represent
  Grid Grid1;                // One Grid object, draws a grid
  PanZoomX PanZoomPlot;      // pan/zoom object to control pan & zoom of main data plot
  
  dataPlot (PApplet p, int plotXpos, int plotYpos, int plotWidth, int plotHeight, int plotDataLen) {
    
    dpXpos = plotXpos;
    dpYpos = plotYpos;
    dpWidth = plotWidth;
    dpHeight = plotHeight;
    dpDataLen = plotDataLen;
  
    PanZoomPlot = new PanZoomX(p, plotDataLen);   // Create PanZoom object to pan & zoom the main data plot
    
    pan_x = PanZoomPlot.getPanX();   // initial pan and zoom values
    scale_x = PanZoomPlot.getScaleX();
    pan_y = PanZoomPlot.getPanY();
    scale_y = PanZoomPlot.getScaleY();
    
    // multiplies the plotted y values of the kernel, for greater height visibility since the values in typical kernels are so small
    kernelMultiplier = 100.0;
    
    // height above bottom of screen to draw the kernel data points                                      
    kernelDrawYOffset = 75; 
    
    // diameter of drawn subpixel marker circles
    markSize = 3;
    
    // sets height deviation of vertical lines from center height, indicates subpixel peaks and shadow center location
    subpixelMarkerLen = int(SCREEN_HEIGHT * 0.01);
   
    // arrays for output signals, get resized after kernel size is known
    output = new float[KERNEL_LENGTH];
    
    // create the Legend object, which lists the colors and what they represent
    Legend1 = new Legend(); 
      
    // create the Grid object, which draws a grid
    Grid1 = new Grid(); 
  }
  
 boolean overKernel() {
    if (mouseX > 0 && mouseX < dpWidth && 
      mouseY > 0 && mouseY > SCREEN_HEIGHT - 120) {
      return true;
    } else {
      return false;
    }
  }
  
  boolean overPlot() {
    if (mouseX > 0 && mouseX < dpWidth && 
      mouseY > 0 && mouseY < SCREEN_HEIGHT - 120) {
      return true;
    } else {
      return false;
    }
  }

  void keyPressed() { // we simply pass through the mouse events to the pan zoom object
    PanZoomPlot.keyPressed();
  }
  
  void mouseDragged() {
    if (overPlot()){
      PanZoomPlot.mouseDragged();
    }
  }
  
  void mouseWheel(int step) {
    if (overKernel()){
        outerPtrX = wDataStopPos;
        innerPtrX = KERNEL_LENGTH_MINUS1;
        KG1.mouseWheel(step);
        output = new float[KERNEL_LENGTH];
    } else if(overPlot()){
      PanZoomPlot.mouseWheel(step);
    }
  }
  
  void display() {
    
    // update the local pan and scale variables from the PanZoom object which maintains them
    pan_x = PanZoomPlot.getPanX();
    scale_x = PanZoomPlot.getScaleX();
    pan_y = PanZoomPlot.getPanY();
    scale_y = PanZoomPlot.getScaleY();
    
    // The minimum number of input data samples is two times the kernel length + 1,  which results in 
    // the minumum of only one sample processed. (we ignore the fist and last data by one kernel's width)
    
    wDataStartPos = 0;
    wDataStopPos = dpDataLen;
    
    //wDataStartPos = constrain(wDataStartPos, 0, dpDataLen);
    //wDataStopPos = constrain(wDataStopPos, 0, dpDataLen);
    
    // draw grid, legend, and kernel
    //Grid1.drawGrid(SCREEN_WIDTH, SCREEN_HEIGHT, 32/scale_x);
    
    //drawGrid2(pan_x, (wDataLen * scale_x) + pan_x, 0, height + pan_y, 64 * scale_x, 256 * scale_y);
    
    Legend1.drawLegend();
    drawKernel(0, scale_x, 0, kernelMultiplier, KG1.sigma);
    
    if (signalSource == 3){         // Plot using Serial Data
      processSerialData();          // from 0 to SENSOR_PIXELS-1              
    } else
    {                               // Plot using Simulated Data
      processSignalGeneratorData(); // from 0 to SENSOR_PIXELS-1
    }
    
    calculateSensorShadowPosition(); // Subpixel calculations  
    
    text("Use mouse to drag, mouse wheel to zoom", HALF_SCREEN_WIDTH-150, 90);
    
    text("pan_x: " + String.format("%.3f", pan_x) + 
    "  scale_x: " + String.format("%.3f", scale_x),
    50, 50);
  }
  
  void drawKernel(float pan_x, float scale_x, float pan_y, float scale_y, float sigma){
    
    // plot kernel data point
    stroke(COLOR_KERNEL_DATA);
    
    for (outerPtrX = 0; outerPtrX < KERNEL_LENGTH; outerPtrX++) { 
      // shift outerPtrX left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
      drawPtrXLessK = ((outerPtrX - HALF_KERNEL_LENGTH) * scale_x) + pan_x; 
  
      // draw new kernel point (y scaled up by kernelMultiplier for better visibility)
      point(drawPtrXLessK+HALF_SCREEN_WIDTH, 
      SCREEN_HEIGHT-kernelDrawYOffset - (kernel[outerPtrX] * scale_y) + pan_y);
     }
     fill(255);
     text("Use mouse wheel here to adjust kernel", HALF_SCREEN_WIDTH-130, (SCREEN_HEIGHT-50));
     text("Kernel Sigma: " + String.format("%.1f", sigma), HALF_SCREEN_WIDTH-60, (SCREEN_HEIGHT-30));
     text("Kernel Length: " + KERNEL_LENGTH, HALF_SCREEN_WIDTH-60, (SCREEN_HEIGHT-10));
  }

  void processSerialData(){
  
    int outerCount = 0;
      
    negPeakLoc = wDataStopPos; // one past the last pixel, to prevent false positives?
    posPeakLoc = wDataStopPos; // one past the last pixel, to prevent false positives?
    negPeakVal = 0;
    posPeakVal = 0;
      
    // increment the outer loop pointer from wDataStartPos to wDataStopPos - 1
    for (outerPtrX = wDataStartPos; outerPtrX < wDataStopPos; outerPtrX++) {
    
      outerCount++; // lets us index (x axis) on the screen offset from outerPtrX
      
      // Below we prepare 3 x shift correction indexes to reduce the math work.
      
      // the outer pointer to the screen X axis (l)
      drawPtrX = (outerCount * scale_x) + pan_x;
    
      // shift left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
      drawPtrXLessK = ((outerCount - HALF_KERNEL_LENGTH) * scale_x) + pan_x; 
 
      drawPtrXLessKlessD1 = (((outerCount - HALF_KERNEL_LENGTH) - 0.5) * scale_x) + pan_x;
       
      // parse one pixel data value from the serial port data byte array:
      // Read a pair of bytes from the byte array, convert them into an integer, 
      // shift right 2 places(divide by 4), and copy the value to a simple global variable
      input = (byteArray[outerPtrX<<1]<< 8 | (byteArray[(outerPtrX<<1) + 1] & 0xFF))>>2;
      
      // plot original data value
      stroke(COLOR_ORIGINAL_DATA);
      
      point(drawPtrX, HALF_SCREEN_HEIGHT - (input * scale_y) + pan_y);
      // draw section of greyscale bar showing the 'color' of original data values
      greyscaleBarMapped(drawPtrX, scale_x, 0, input);

      // ================================= Convolution Inner Loop  =============================================
      cOutPrev = cOut; // y[output-1] (the previous convolution output value)
      
      for (innerPtrX = 0; innerPtrX < KERNEL_LENGTH_MINUS1; innerPtrX++) {     // increment the inner loop pointer
        output[innerPtrX] = output[innerPtrX+1] + (input * kernel[innerPtrX]); // convolution: multiply and accumulate
      }
      
      output[KERNEL_LENGTH_MINUS1] = input * kernel[KERNEL_LENGTH_MINUS1]; // convolution: multiply only, no accumulate
      
      cOut = output[0]; // y[output] (the latest convolution output value)
      
      // To make this convolution inner loop easier to understand, I unwrap the loop below 
      // Try it, the unwrapped loop code runs fine, but don't mess with the kernel size via the mouse;
      // (The default kernel sigma 1.4 creates 9 kernel points, which we assume below.)
      // Remember to comment out the original convolution code above or you will convolve the input data twice.
      // Assuming a 9 point kernel:
      
      //cOutPrev = cOut; // y[output-1] (the previous convolution output value)
      
      //output[0] = output[1] + (input * kernel[0]); // 1st kernel point, convolution: multiply and accumulate
      //output[1] = output[2] + (input * kernel[1]); // 2nd kernel point, convolution: multiply and accumulate
      //output[2] = output[3] + (input * kernel[2]); // 3rd kernel point, convolution: multiply and accumulate
      //output[3] = output[4] + (input * kernel[3]); // 4th kernel point, convolution: multiply and accumulate
      //output[4] = output[5] + (input * kernel[4]); // 5th kernel point, convolution: multiply and accumulate
      //output[5] = output[6] + (input * kernel[5]); // 6th kernel point, convolution: multiply and accumulate
      //output[6] = output[7] + (input * kernel[6]); // 7th kernel point, convolution: multiply and accumulate
      //output[7] = output[8] + (input * kernel[7]); // 8th kernel point, convolution: multiply and accumulate
      //output[8] = input * kernel[8];               // 9th kernel point, convolution: multiply only, no accumulate
      
      //cOut = output[0]; // y[output] (the current convolution output value)
      
      // ==================================== End Convolution ==================================================
      
      // =================== Find the 1st difference and store the last two values  =============================
      // finds the differences and maintains a history of the previous 2 difference values as well,
      // so we can collect all 3 points bracketing a pos or neg peak, needed to feed the subpixel code.
      
      diff2=diff1;      // (left y value)
      diff1=diff0;      // (center y value)  
      // find 1st difference of the convolved data, the difference between adjacent points in the smoothed data.
      diff0 = cOut - cOutPrev; // (right y value) // difference between the current convolution output value 
      // and the previous one, in the form y[x] - y[x-1]
      // In dsp, this difference is preferably called the 1st difference, 
      // but some call it the 1st derivative or the partial derivative.
      
      // =============================================================================================
  
      // plot the output data value
      stroke(COLOR_OUTPUT_DATA);
      point(drawPtrXLessK, HALF_SCREEN_HEIGHT - (cOut * scale_y) + pan_y);
      //println("output[" + outerPtrX + "]" +output[outerPtrX]);
     
      // draw section of greyscale bar showing the 'color' of output data values
      greyscaleBarMapped(drawPtrXLessK, scale_x, 11, cOut);
      
      // plot the first difference data value
      stroke(COLOR_FIRST_DIFFERENCE_OF_OUTPUT);
      point((drawPtrXLessKlessD1), HALF_SCREEN_HEIGHT - (diff0 * scale_y) + pan_y);
      // draw section of greyscale bar showing the 'color' of output2 data values
      //void greyscaleBarMapped(float x, float scale_x, float y, float value) {
      greyscaleBarMappedAbs((drawPtrXLessKlessD1), scale_x, 22, diff0);
      
      // find the the tallest positive and negative peaks in 1st difference of the convolution output data, 
      // which is the point of steepest positive and negative slope
      // We skip the first KERNEL_LENGTH of convolution output data, which is garbage from smoothing convolution 
      // kernel not being fully immersed in the input data.
      if (outerCount > KERNEL_LENGTH_MINUS1) {  // skip the first kernel's width of values which are garbage
        if (diff1 > posPeakVal) {
          posPeakVal = diff1;
          posPeakLoc = (outerPtrX - 1.5) - HALF_KERNEL_LENGTH; // x-1
          posPeakRightPixel = diff0;   // y value @ x index -1 (right)
          posPeakCenterPixel = diff1;  // y value @ x index -2 (center) (positive 1st difference peak location)
          posPeakLeftPixel = diff2;    // y value @ x index -3 (left)
        }else if (diff1 < negPeakVal) {
          negPeakVal = diff1;
          negPeakLoc = (outerPtrX - 1.5) - HALF_KERNEL_LENGTH; // x-1
          negPeakRightPixel = diff0;   // y value @ x index -1 (right)
          negPeakCenterPixel = diff1;  // y value @ x index -2 (center) (negative 1st difference peak location)
          negPeakLeftPixel = diff2;    // y value @ x index -3 (left)
        }
      }
    }
  }
      // copy one data value from the signal generator output array:
      //input = sigGenOutput[outerPtrX];
  void processSignalGeneratorData(){
    
    int outerCount = 0;
      
    negPeakLoc = wDataStopPos; // one past the last pixel, to prevent false positives?
    posPeakLoc = wDataStopPos; // one past the last pixel, to prevent false positives?
    negPeakVal = 0;
    posPeakVal = 0;
      
    // increment the outer loop pointer from wDataStartPos to wDataStopPos - 1
    for (outerPtrX = wDataStartPos; outerPtrX < wDataStopPos; outerPtrX++) {
    
      outerCount++; // lets us index (x axis) on the screen offset from outerPtrX
      
      // Below we prepare 3 x shift correction indexes to reduce the math work.
      
      // the outer pointer to the screen X axis (l)
      drawPtrX = (outerCount * scale_x) + pan_x;
    
      // shift left by half the kernel size to correct for convolution shift (dead-on correct for odd-size kernels)
      drawPtrXLessK = ((outerCount - HALF_KERNEL_LENGTH) * scale_x) + pan_x; 
 
      drawPtrXLessKlessD1 = (((outerCount - HALF_KERNEL_LENGTH) - 0.5) * scale_x) + pan_x;
       
      // copy one data value from the signal generator output array:
      input = sigGenOutput[outerPtrX];
      
      // plot original data value
      stroke(COLOR_ORIGINAL_DATA);
      
      point(drawPtrX, HALF_SCREEN_HEIGHT - (input * scale_y) + pan_y);
      // draw section of greyscale bar showing the 'color' of original data values
      greyscaleBarMapped(drawPtrX, scale_x, 0, input);
      
      // ================================= Convolution Inner Loop  =============================================
      cOutPrev = cOut; // y[output-1] (the previous convolution output value)
      
      for (innerPtrX = 0; innerPtrX < KERNEL_LENGTH_MINUS1; innerPtrX++) {     // increment the inner loop pointer
        output[innerPtrX] = output[innerPtrX+1] + (input * kernel[innerPtrX]); // convolution: multiply and accumulate
      }
      
      output[KERNEL_LENGTH_MINUS1] = input * kernel[KERNEL_LENGTH_MINUS1]; // convolution: multiply only, no accumulate
      
      cOut = output[0]; // y[output] (the latest convolution output value)
      
      // To make this convolution inner loop easier to understand, I unwrap the loop below 
      // Try it, the unwrapped loop code runs fine, but don't mess with the kernel size via the mouse;
      // (The default kernel sigma 1.4 creates 9 kernel points, which we assume below.)
      // Remember to comment out the original convolution code above or you will convolve the input data twice.
      // Assuming a 9 point kernel:
      
      //cOutPrev = cOut; // y[output-1] (the previous convolution output value)
      
      //output[0] = output[1] + (input * kernel[0]); // 1st kernel point, convolution: multiply and accumulate
      //output[1] = output[2] + (input * kernel[1]); // 2nd kernel point, convolution: multiply and accumulate
      //output[2] = output[3] + (input * kernel[2]); // 3rd kernel point, convolution: multiply and accumulate
      //output[3] = output[4] + (input * kernel[3]); // 4th kernel point, convolution: multiply and accumulate
      //output[4] = output[5] + (input * kernel[4]); // 5th kernel point, convolution: multiply and accumulate
      //output[5] = output[6] + (input * kernel[5]); // 6th kernel point, convolution: multiply and accumulate
      //output[6] = output[7] + (input * kernel[6]); // 7th kernel point, convolution: multiply and accumulate
      //output[7] = output[8] + (input * kernel[7]); // 8th kernel point, convolution: multiply and accumulate
      //output[8] = input * kernel[8];               // 9th kernel point, convolution: multiply only, no accumulate
      
      //cOut = output[0]; // y[output] (the current convolution output value)
      
      // ==================================== End Convolution ==================================================
      
      // =================== Find the 1st difference and store the last two values  =============================
      // finds the differences and maintains a history of the previous 2 difference values as well,
      // so we can collect all 3 points bracketing a pos or neg peak, needed to feed the subpixel code.
      
      diff2=diff1;      // (left y value)
      diff1=diff0;      // (center y value)  
      // find 1st difference of the convolved data, the difference between adjacent points in the smoothed data.
      diff0 = cOut - cOutPrev; // (right y value) // difference between the current convolution output value 
      // and the previous one, in the form y[x] - y[x-1]
      // In dsp, this difference is preferably called the 1st difference, 
      // but some call it the 1st derivative or the partial derivative.
      
      // =============================================================================================
  
      // plot the output data value
      stroke(COLOR_OUTPUT_DATA);
      point(drawPtrXLessK, HALF_SCREEN_HEIGHT - (cOut * scale_y) + pan_y);
      //println("output[" + outerPtrX + "]" +output[outerPtrX]);
     
      // draw section of greyscale bar showing the 'color' of output data values
      greyscaleBarMapped(drawPtrXLessK, scale_x, 11, cOut);
      
      // plot the first difference data value
      stroke(COLOR_FIRST_DIFFERENCE_OF_OUTPUT);
      point((drawPtrXLessKlessD1), HALF_SCREEN_HEIGHT - (diff0 * scale_y) + pan_y);
      // draw section of greyscale bar showing the 'color' of output2 data values
      //void greyscaleBarMapped(float x, float scale_x, float y, float value) {
      greyscaleBarMappedAbs((drawPtrXLessKlessD1), scale_x, 22, diff0);
      
      // find the the tallest positive and negative peaks in 1st difference of the convolution output data, 
      // which is the point of steepest positive and negative slope
      // We skip the first KERNEL_LENGTH of convolution output data, which is garbage from smoothing convolution 
      // kernel not being fully immersed in the input data.
      if (outerCount > KERNEL_LENGTH_MINUS1) {  // skip the first kernel's width of values which are garbage
        if (diff1 > posPeakVal) {
          posPeakVal = diff1;
          posPeakLoc = (outerPtrX - 1.5) - HALF_KERNEL_LENGTH; // x-1
          posPeakRightPixel = diff0;   // y value @ x index -1 (right)
          posPeakCenterPixel = diff1;  // y value @ x index -2 (center) (positive 1st difference peak location)
          posPeakLeftPixel = diff2;    // y value @ x index -3 (left)
        }else if (diff1 < negPeakVal) {
          negPeakVal = diff1;
          negPeakLoc = (outerPtrX - 1.5) - HALF_KERNEL_LENGTH; // x-1
          negPeakRightPixel = diff0;   // y value @ x index -1 (right)
          negPeakCenterPixel = diff1;  // y value @ x index -2 (center) (negative 1st difference peak location)
          negPeakLeftPixel = diff2;    // y value @ x index -3 (left)
        }
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
    
    // we should have already ran a gaussian smoothing routine over the data, and 
    // found the x location and y values for the positive and negative peaks of the first differences,
    // and the neighboring first differences immediately to the left and right of these on the x axis.
    // Therefore, all we have remaining to do, is the quadratic interpolation routines and the actual 
    // drawing, after a quality check of the peak heights and width between them.
    
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
     
    preciseWidth = 0;
    precisePosition = 0;
    negPeakSubPixelLoc = 0;
    posPeakSubPixelLoc = 0;
    
    if (negPeakVal < -64 && posPeakVal > 64) // check for significant threshold
    {
      widthInPixels=posPeakLoc-negPeakLoc;
    } else 
    {
      widthInPixels = 0;
    }

    // check for width in acceptable range, what is acceptable is up to you, within reason.
    if(widthInPixels > 8 && widthInPixels < 512) { // was originally 103 for filiment width app, (15.7pixels per mm, 65535/635=103)
      
      // sub-pixel edge detection using interpolation
      // from Accelerated Image Processing blog, posting: Sub-Pixel Maximum
      // https://visionexperts.blogspot.com/2009/03/sub-pixel-maximum.html
      
      // for the subpixel value of the greatest negative peak found above, 
      // corresponds with the left edge of a narrow shadow cast upon the sensor
      negPeakSubPixelLoc = 0.5 * (negPeakLeftPixel - negPeakRightPixel) / (negPeakLeftPixel - (2 * negPeakCenterPixel) + negPeakRightPixel);
      
      // for the subpixel value of the greatest positive peak found above, 
      // corresponds with the right edge of a narrow shadow cast upon the sensor
      posPeakSubPixelLoc = 0.5 * (posPeakLeftPixel - posPeakRightPixel) / (posPeakLeftPixel - (2 * posPeakCenterPixel) + posPeakRightPixel);

      // original function translated from flipper's filament width sensor; does the same math calculation as above
      // negPeakSubPixelLoc=((a1-c1) / (a1+c1-(b1*2)))/2;
      // posPeakSubPixelLoc=((a2-c2) / (a2+c2-(b2*2)))/2;

      preciseWidth = widthInPixels + (posPeakSubPixelLoc - negPeakSubPixelLoc);
      preciseWidthLowPass = (preciseWidthLowPass * 0.9) + (preciseWidth * 0.1);            // apply a simple low pass filter
      preciseWidthMM = preciseWidthLowPass * sensorPixelSpacing * calibrationCoefficient;

      //println(calibrationCoefficient);
      
      // solve for the center position
      precisePosition = (((negPeakLoc + negPeakSubPixelLoc) + (posPeakLoc + posPeakSubPixelLoc)) / 2);
      precisePositionLowPass = (precisePositionLowPass * 0.9) + (precisePosition * 0.1);   // apply a simple low pass filter
      
      preciseMMPos = precisePositionLowPass * sensorPixelSpacing;

       // sum of a few offsets, so we don't need to recalculate
      shiftSumX = wDataStartPos - 1; 

      // Mark negPeakSubPixelLoc with red line
      noFill();
      strokeWeight(1);
      stroke(255, 0, 0);
      XCoord = (float)((negPeakLoc + negPeakSubPixelLoc - shiftSumX) * scale_x) + pan_x;
      line(XCoord, HALF_SCREEN_HEIGHT + subpixelMarkerLen, XCoord, HALF_SCREEN_HEIGHT - subpixelMarkerLen);
 
      // Mark posPeakSubPixelLoc with green line
      stroke(0, 255, 0);
      XCoord = (float)((posPeakLoc + posPeakSubPixelLoc - shiftSumX) * scale_x) + pan_x;
      line(XCoord, HALF_SCREEN_HEIGHT + subpixelMarkerLen, XCoord, HALF_SCREEN_HEIGHT - subpixelMarkerLen);

      // Mark subpixel center with white line
      stroke(255);
      XCoord = (float)((precisePositionLowPass - shiftSumX) * scale_x) + pan_x;
      line(XCoord, HALF_SCREEN_HEIGHT + subpixelMarkerLen, XCoord, HALF_SCREEN_HEIGHT - subpixelMarkerLen); 

      // Mark negPeakLoc 3 pixel cluster with one red circle each
      stroke(255, 0, 0);
      ellipse((float) ((negPeakLoc - shiftSumX - 1) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (negPeakLeftPixel * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((negPeakLoc - shiftSumX - 0) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (negPeakCenterPixel * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((negPeakLoc - shiftSumX + 1) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (negPeakRightPixel * scale_y) + pan_y), markSize, markSize);

      // Mark posPeakLoc 3 pixel cluster with one green circle each
      stroke(0, 255, 0);
      ellipse((float) ((posPeakLoc - shiftSumX - 1) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (posPeakLeftPixel * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((posPeakLoc - shiftSumX - 0) * scale_x) + pan_x,  (float) (HALF_SCREEN_HEIGHT - (posPeakCenterPixel * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((posPeakLoc - shiftSumX + 1) * scale_x) + pan_x,  (float) (HALF_SCREEN_HEIGHT - (posPeakRightPixel * scale_y) + pan_y), markSize, markSize);
      
      YCoord = SCREEN_HEIGHT - 140;
      fill(255);
      textSize(14);
      text("neg Peak Location: " + negPeakLoc, HALF_SCREEN_WIDTH - 500, YCoord);
      text("pos Peak Location: " + posPeakLoc, HALF_SCREEN_WIDTH - 300, YCoord);
      text("neg SubPixel Location: " + String.format("%.3f", negPeakSubPixelLoc), HALF_SCREEN_WIDTH + 50, YCoord);
      text("pos SubPixel Location: " + String.format("%.3f", posPeakSubPixelLoc), HALF_SCREEN_WIDTH + 325, YCoord);
      
      YCoord += 20;
      
      text("Subpixel Width: " + String.format("%.3f", preciseWidthLowPass), HALF_SCREEN_WIDTH -500, YCoord);
      text("Subpixel Center Position = " + String.format("%.3f", precisePositionLowPass), HALF_SCREEN_WIDTH - 300, YCoord);
      text("Width in mm: " + String.format("%.5f", preciseWidthMM), HALF_SCREEN_WIDTH + 50, YCoord);
      text("Position in mm: " + String.format("%.5f", preciseMMPos), HALF_SCREEN_WIDTH + 325, YCoord);
    }
  }
}