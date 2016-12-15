class dataPlot {
  // by Douglas Mayhew 12/1/2016
  // Plots data and provides mouse sliding and zooming ability
  
  int dpXpos;              // dataPlot class init variables
  int dpYpos;
  int dpWidth;
  int dpHeight;
  int dpDataLen;
  
  int in;                  // a single convolution input y value
  float outMinus1;         // the previous convolution output y value
  float out0;              // the current convolution output y value
  
  
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
  float drawPtrXLessKandD1 = 0;
  // =============================================================================================
  // Subpixel Variables
  int negPeakLoc;             // x index position of greatest negative y difference peak found in 1st difference data
  int posPeakLoc;             // x index position of greatest positive y difference peak found in 1st difference data
  int markSize;               // diameter of drawn subpixel marker circles
  int subpixelMarkerLen;      // length of vertical lines which indicate subpixel peaks and shadow center location
  int widthInPixels;          // integer difference between the two peaks without subpixel precision
  double negPeakVal;          // value of greatest negative y difference peak found in 1st difference data
  double posPeakVal;          // value of greatest positive y difference peak found in 1st difference data 
  double a1, b1, c1;          // sub pixel quadratic interpolation negative y difference peak and left/right neighbors
  double a2, b2, c2;          // sub pixel quadratic interpolation positive y difference peak and left/right neighbors
  double negPeakSubPixelLoc;  // quadratic interpolated negative peak subpixel x position; 
  double posPeakSubPixelLoc;  // quadratic interpolated positive peak subpixel x position
  double preciseWidth;        // filament width output in pixels
  double preciseWidthLowPass; // width filtered with simple running average filter
  double preciseWidthMM;      // filament width output in mm
  double precisePosition;     // center position output in pixels
  double precisePositionLowPass; // position filtered with simple running average filter
  double preciseMMPos;        // canter position output in mm
  double shiftSumX;           // temporary variable for summing x shift values
  double calibrationCoefficient = 0.9822050932057512; // corrects mm width by multiplying by this value
  
  float d0, d1, d2, d3;       // temp variables which hold derivative values, used instead of another array
  float  XCoord;              // temporary variable for holding a screen X coordinate
  float  YCoord;              // temporary variable for holding a screen Y coordinate
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
     text("Kernel Sigma: " + String.format("%.1f", sigma), HALF_SCREEN_WIDTH-60, (SCREEN_HEIGHT-20));
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
      
      // shift left by half the kernel length and,
      // shift left by half a data point increment to properly position the 1st difference points in-beween the original data points.
      drawPtrXLessKandD1 = ((outerCount - HALF_KERNEL_LENGTH -0.5) * scale_x) + pan_x;
 
      // parse one pixel data value from the serial port data byte array:
      // Read a pair of bytes from the byte array, convert them into an integer, 
      // shift right 2 places(divide by 4), and copy result to 'in'
      in = (byteArray[outerPtrX<<1]<< 8 | (byteArray[(outerPtrX<<1) + 1] & 0xFF))>>2;
      
      // plot original data point
      stroke(COLOR_ORIGINAL_DATA);
      
      point(drawPtrX, HALF_SCREEN_HEIGHT - (in * scale_y) + pan_y);
      // draw section of greyscale bar showing the 'color' of original data values
      greyscaleBarMapped(drawPtrX, scale_x, 0, in);
      
      // convolution inner loop
      outMinus1 = out0; // y at previous x index
      for (innerPtrX = 0; innerPtrX < KERNEL_LENGTH_MINUS1; innerPtrX++) { // increment the inner loop pointer
        output[innerPtrX] = output[innerPtrX+1] + in * kernel[innerPtrX];  // convolve: multiply and accumulate
      }
      output[KERNEL_LENGTH_MINUS1] = in * kernel[KERNEL_LENGTH_MINUS1];
      out0 = output[0]; // y at current x index
     
      // plot the output data
      stroke(COLOR_OUTPUT_DATA);
      point(drawPtrXLessK, HALF_SCREEN_HEIGHT - (out0 * scale_y) + pan_y);
      //println("output[" + outerPtrX + "]" +output[outerPtrX]);
     
      // draw section of greyscale bar showing the 'color' of output data values
      greyscaleBarMapped(drawPtrXLessK, scale_x, 11, out0);
      
      // find 1st difference of the convolved data, the difference between adjacent points in the smoothed data.
      // We skip the first KERNEL_LENGTH of convolution output data, which is garbage from smoothing convolution 
      // kernel not being fully immersed in the input data.
     if (outerCount > KERNEL_LENGTH_MINUS1) {  // skip the first kernel's width of values which are garbage
        d3=d2; // y value @ x index -3
        d2=d1; // y value @ x index -2
        d1=d0; // y value @ x index -1
        d0 = out0 - outMinus1; // the difference between adjacent points, in dsp preferably called the 1st difference
        
        stroke(COLOR_FIRST_DIFFERENCE_OF_OUTPUT);
        point(drawPtrXLessKandD1, HALF_SCREEN_HEIGHT - (d0 * scale_y) + pan_y);
        // draw section of greyscale bar showing the 'color' of output2 data values
        //void greyscaleBarMapped(float x, float scale_x, float y, float value) {
        greyscaleBarMappedAbs(drawPtrXLessKandD1, scale_x, 22, d0);
        // find the the tallest positive and negative peaks in 1st difference of the convolution output data, 
        // which is the point of steepest positive and negative slope
        if (d2 > posPeakVal) {
          posPeakLoc = outerPtrX-2 - HALF_KERNEL_LENGTH; // x index -2
          c2=d1; // y value @ x index -1
          b2=d2; // y value @ x index -2 (positive 1st difference peak location)
          a2=d3; // y value @ x index -3
          posPeakVal = d2;
        }else if (d2 < negPeakVal) {
          negPeakLoc = outerPtrX-2 - HALF_KERNEL_LENGTH; // x index -2
          c1=d1; // y value @ x index -1
          b1=d2; // y value @ x index -2 (negative 1st difference peak location)
          a1=d3; // y value @ x index -3
          negPeakVal = d2;
        }
      }
    }
  }

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
      
      // shift left by half the kernel length and,
      // shift left by half a data point increment to properly position the 1st difference points in-beween the original data points.
      drawPtrXLessKandD1 = ((outerCount - HALF_KERNEL_LENGTH -0.5) * scale_x) + pan_x;
 
      // copy one data value from the signal generator output array:
      in = sigGenOutput[outerPtrX];
      
      // plot original data point
      stroke(COLOR_ORIGINAL_DATA);
      
      point(drawPtrX, HALF_SCREEN_HEIGHT - (in * scale_y) + pan_y);
      // draw section of greyscale bar showing the 'color' of original data values
      greyscaleBarMapped(drawPtrX, scale_x, 0, in);
      
      // convolution inner loop
      outMinus1 = out0; // y at previous x index
      for (innerPtrX = 0; innerPtrX < KERNEL_LENGTH_MINUS1; innerPtrX++) { // increment the inner loop pointer
        output[innerPtrX] = output[innerPtrX+1] + in * kernel[innerPtrX];  // convolve: multiply and accumulate
      }
      output[KERNEL_LENGTH_MINUS1] = in * kernel[KERNEL_LENGTH_MINUS1];
      out0 = output[0]; // y at current x index
     
      // plot the output data
      stroke(COLOR_OUTPUT_DATA);
      point(drawPtrXLessK, HALF_SCREEN_HEIGHT - (out0 * scale_y) + pan_y);
      //println("output[" + outerPtrX + "]" +output[outerPtrX]);
     
      // draw section of greyscale bar showing the 'color' of output data values
      greyscaleBarMapped(drawPtrXLessK, scale_x, 11, out0);
      
      // find 1st difference of the convolved data, the difference between adjacent points in the smoothed data.
      // We skip the first KERNEL_LENGTH of convolution output data, which is garbage from smoothing convolution 
      // kernel not being fully immersed in the input data.
     if (outerCount > KERNEL_LENGTH_MINUS1) {  // skip the first kernel's width of values which are garbage
        d3=d2; // y value @ x index -3 (left)
        d2=d1; // y value @ x index -2 (center)
        d1=d0; // y value @ x index -1 (right)
        d0 = out0 - outMinus1; // the difference between adjacent points, in dsp preferably called the 1st difference
        
        stroke(COLOR_FIRST_DIFFERENCE_OF_OUTPUT);
        point(drawPtrXLessKandD1, HALF_SCREEN_HEIGHT - (d0 * scale_y) + pan_y);
        // draw section of greyscale bar showing the 'color' of output2 data values
        //void greyscaleBarMapped(float x, float scale_x, float y, float value) {
        greyscaleBarMappedAbs(drawPtrXLessKandD1, scale_x, 22, d0);
        // find the the tallest positive and negative peaks in 1st difference of the convolution output data, 
        // which is the point of steepest positive and negative slope
        if (d2 > posPeakVal) {
          posPeakLoc = outerPtrX-2 - HALF_KERNEL_LENGTH; // x index -2
          c2=d1; // y value @ x index -1 (right)
          b2=d2; // y value @ x index -2 (center) (positive 1st difference peak location)
          a2=d3; // y value @ x index -3 (left)
          posPeakVal = d2;
        }else if (d2 < negPeakVal) {
          negPeakLoc = outerPtrX-2 - HALF_KERNEL_LENGTH; // x index -2
          c1=d1; // y value @ x index -1 (right)
          b1=d2; // y value @ x index -2 (center) (negative 1st difference peak location)
          a1=d3; // y value @ x index -3 (left)
          negPeakVal = d2;
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
      widthInPixels=0;
    }

    // check for width in acceptable range, what is acceptable is up to you, within reason.
    if(widthInPixels > 8 && widthInPixels < 512) { // was originally 103 for filiment width app, (15.7pixels per mm, 65535/635=103)
      
      // sub-pixel edge detection using interpolation
      // from Accelerated Image Processing blog, posting: Sub-Pixel Maximum
      // https://visionexperts.blogspot.com/2009/03/sub-pixel-maximum.html
      
      // for the subpixel value of the greatest negative peak found above, 
      // corresponds with the left edge of a narrow shadow cast upon the sensor
      negPeakSubPixelLoc = 0.5 * (a1 - c1) / (a1 - 2 * b1 + c1);
      
      // for the subpixel value of the greatest positive peak found above, 
      // corresponds with the right edge of a narrow shadow cast upon the sensor
      posPeakSubPixelLoc = 0.5 * (a2 - c2) / (a2 - 2 * b2 + c2);

      // original function translated from flipper's filament width sensor; does the same math calculation as above
      // negPeakSubPixelLoc=((a1-c1) / (a1+c1-(b1*2)))/2;
      // posPeakSubPixelLoc=((a2-c2) / (a2+c2-(b2*2)))/2;

      preciseWidth = widthInPixels + (posPeakSubPixelLoc - negPeakSubPixelLoc);
      preciseWidthLowPass = (preciseWidthLowPass * 0.9) + (preciseWidth * 0.1);
      preciseWidthMM = preciseWidthLowPass * sensorPixelSpacing * calibrationCoefficient;

      //println(calibrationCoefficient);
      
      // solve for the center position
      precisePosition = (((negPeakLoc + negPeakSubPixelLoc) + (posPeakLoc + posPeakSubPixelLoc)) / 2);
      precisePositionLowPass = (precisePositionLowPass * 0.9) + (precisePosition * 0.1);
      
      preciseMMPos = precisePositionLowPass * sensorPixelSpacing;

       // sum of a few offsets, so we don't need to recalculate
      shiftSumX =  0.5 + wDataStartPos - 1; 

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
      ellipse((float) ((negPeakLoc - shiftSumX - 1) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (a1 * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((negPeakLoc - shiftSumX) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (b1 * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((negPeakLoc - shiftSumX + 1) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (c1 * scale_y) + pan_y), markSize, markSize);

      // Mark posPeakLoc 3 pixel cluster with one green circle each
      stroke(0, 255, 0);
      ellipse((float) ((posPeakLoc - shiftSumX - 1) * scale_x) + pan_x, (float) (HALF_SCREEN_HEIGHT - (a2 * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((posPeakLoc - shiftSumX) * scale_x) + pan_x,  (float) (HALF_SCREEN_HEIGHT - (b2 * scale_y) + pan_y), markSize, markSize);
      ellipse((float) ((posPeakLoc - shiftSumX + 1) * scale_x) + pan_x,  (float) (HALF_SCREEN_HEIGHT - (c2 * scale_y) + pan_y), markSize, markSize);
      
      XCoord = HALF_SCREEN_WIDTH;
      YCoord = SCREEN_HEIGHT - 120;
      fill(255);
      textSize(14);
      //text("negPeakLoc: " + negPeakLoc, 0, YCoord);
      //text("posPeakLoc: " + posPeakLoc, 125, YCoord);
      //text("negPeakSubPixelLoc: " + String.format("%.3f", negPeakSubPixelLoc), 250, YCoord);
      //text("posPeakSubPixelLoc: " + String.format("%.3f", posPeakSubPixelLoc), 325, YCoord);
      text("Width in Pixels: " + String.format("%.3f", preciseWidthLowPass), XCoord - 450, YCoord);
      text("Position in Pixels = " + String.format("%.3f", precisePositionLowPass), XCoord - 250, YCoord);
      text("Width mm: " + String.format("%.5f", preciseWidthMM), XCoord + 75, YCoord);
      text("Position mm: " + String.format("%.5f", preciseMMPos), XCoord + 250, YCoord);
    }
  }
}