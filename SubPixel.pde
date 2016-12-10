class SubPixel {
  // by Douglas Mayhew 12/1/2016
  
  final static float sensorPixelSpacing = 0.0635;           // 63.5 microns
  final static float sensorPixelsPerMM = 15.74803149606299; // number of pixels per mm in sensor TSL1402R and TSL1410R
  final static float sensorWidthAllPixels = 16.256;         // millimeters
  
  SubPixel () {

  }
  
  void calculateSensorShadowPosition(float pan_x, float scale_x, float pan_y, float scale_y, int dataStartPos, int dataStopPos){
    
    int loopStartPos, loopEndPos; 
    int negPeak, posPeak;                    // peak values, y axis (height centric)
    int negPeakLoc, posPeakLoc;              // array index locations of greatest negative & positive peak values in 1st difference data
    float a1, b1, c1, a2, b2, c2;            // sub pixel quadratic interpolation input variables, 3 per D1 peak, one negative, one positive
    float negPeakSubPixelLoc;                // quadratic interpolated negative peak subpixel x position; 
    float posPeakSubPixelLoc;                // quadratic interpolated positive peak subpixel x position
    float preciseWidth = 0;                  // filament width is still here if you need it
    float preciseWidthMM = 0;                // filament width in mm is still here if you need it
    float precisePosition = 0;               // final output
    float preciseMMPos = 0;                  // final mm output
    float roughWidth = 0;                    // integer difference between the two peaks without subpixel precision
    float shiftSumX = 0;                     // temporary variable for summing x shift values
    float XCoord = 0;                        // temporary variable for holding a screen X coordinate
    float YCoord = 0;                        // temporary variable for holding a screen Y coordinate
    
    // skip a kernel width of points to avoid the 1st difference peak at the very beginning of the array
    loopStartPos = dataStartPos + KERNEL_LENGTH;  
    loopEndPos = dataStopPos; // for clarity & consistency follow the same convention as loopStartPos
    
    negPeak = 0;                             // value of greatest negative peak found during scan of difference data
    posPeak = 0;                             // value of greatest positive peak found during scan of difference data
    
    negPeakLoc = dataStopPos; // one past the last pixel, to prevent false positives?
    posPeakLoc = dataStopPos; // one past the last pixel, to prevent false positives?
     
    //clear the sub-pixel buffers
    a1 = b1 = c1 = a2 = b2 = c2 = 0;
    negPeakSubPixelLoc = posPeakSubPixelLoc = 0;
    
    // we should have already ran a gaussian smoothing routine over the data, and 
    // also already saved the 1st difference of the smoothed data into an array.
    // Therefore, all we do here is find the peaks on the 1st difference data.

    for (int i = loopStartPos; i < loopEndPos - 1; i++) {
    // find the the tallest positive and negative peaks in 1st difference of the convolution output data, 
    // which is the point of steepest positive and negative slope in the smoothed original data.
      if (output2[i] > posPeak) {
        posPeak = output2[i];
        posPeakLoc = i;
      }else if (output2[i] < negPeak) {
        negPeak = output2[i];
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

    if (negPeak<-64 && posPeak>64)  // check for significant threshold
    {
      roughWidth=posPeakLoc-negPeakLoc;
    } else 
    {
      roughWidth=0;
    }

    // check for width out of range (15.7pixels per mm, 65535/635=103)
    if(roughWidth > 8 && roughWidth < 103)
      {
      // sub-pixel edge detection using interpolation
      // from Accelerated Image Processing blog, posting: Sub-Pixel Maximum
      // https://visionexperts.blogspot.com/2009/03/sub-pixel-maximum.html
      
      // the subpixel location of a shadow edge is found as the peak of a parabola fitted to 
      // the top 3 points of a smoothed original data's first difference peak.
      
      // the first difference is simply the individual differences between all adjacent data 
      // points of the original data collected up together, in this case stored in a seperate array.
      // Each difference value is proportional to the steepness and direction of the slope in the 
      // original data.
      // Also in this case we smooth the original data first to make the peaks we are searching for
      // more symmectrical and rounded, and thus closer to the shape of a parabola, which we fit to 
      // the peaks next. The more the highest (or lowest for negative peaks) 3 points of the peaks 
      // resemble a parabola, the more accurate the subpixel result.
      
      
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
      line(XCoord, HALF_SCREEN_HEIGHT + subpixelMarkerLen, XCoord, HALF_SCREEN_HEIGHT - subpixelMarkerLen);
 
      // Mark posPeakSubPixelLoc with green line
      stroke(0, 255, 0);
      XCoord = ((posPeakLoc + posPeakSubPixelLoc - shiftSumX) * scale_x) + pan_x;
      line(XCoord, HALF_SCREEN_HEIGHT + subpixelMarkerLen, XCoord, HALF_SCREEN_HEIGHT - subpixelMarkerLen);

      // Mark subpixel center with white line
      stroke(255);
      XCoord = ((precisePosition - shiftSumX) * scale_x) + pan_x;
      line(XCoord, HALF_SCREEN_HEIGHT + subpixelMarkerLen, XCoord, HALF_SCREEN_HEIGHT - subpixelMarkerLen); 

      // Mark negPeakLoc 3 pixel cluster with one red circle each
      stroke(255, 0, 0);
      ellipse(((negPeakLoc - shiftSumX - 1) * scale_x) + pan_x, HALF_SCREEN_HEIGHT - (a1 * scale_y) + pan_y, markSize, markSize);
      ellipse(((negPeakLoc - shiftSumX) * scale_x) + pan_x, HALF_SCREEN_HEIGHT - (b1 * scale_y) + pan_y, markSize, markSize);
      ellipse(((negPeakLoc - shiftSumX + 1) * scale_x) + pan_x, HALF_SCREEN_HEIGHT - (c1 * scale_y) + pan_y, markSize, markSize);

      // Mark posPeakLoc 3 pixel cluster with one green circle each
      stroke(0, 255, 0);
      ellipse(((posPeakLoc - shiftSumX - 1) * scale_x) + pan_x, HALF_SCREEN_HEIGHT - (a2 * scale_y) + pan_y, markSize, markSize);
      ellipse(((posPeakLoc - shiftSumX) * scale_x) + pan_x,  HALF_SCREEN_HEIGHT - (b2 * scale_y) + pan_y, markSize, markSize);
      ellipse(((posPeakLoc - shiftSumX + 1) * scale_x) + pan_x,  HALF_SCREEN_HEIGHT - (c2 * scale_y) + pan_y, markSize, markSize);
      
      YCoord = SCREEN_HEIGHT-120;
      fill(255);
      textSize(14);
      //text("negPeakLoc = " + negPeakLoc, 0, YCoord);
      //text("posPeakLoc = " + posPeakLoc, 125, YCoord);
      //text("negPeakSubPixelLoc = " + String.format("%.3f", negPeakSubPixelLoc), 250, YCoord);
      //text("posPeakSubPixelLoc = " + String.format("%.3f", posPeakSubPixelLoc), 325, YCoord);
      text("preciseWidth = " + String.format("%.3f", preciseWidth), 100, YCoord);
      text("preciseWidthMM =  " + String.format("%.3f", preciseWidthMM), 275, YCoord);
      text("precisePosition = " + String.format("%.3f", precisePosition), 475, YCoord);
      text("PreciseMMPos =  " + String.format("%.3f", preciseMMPos), 675, YCoord);
    }
  }
}