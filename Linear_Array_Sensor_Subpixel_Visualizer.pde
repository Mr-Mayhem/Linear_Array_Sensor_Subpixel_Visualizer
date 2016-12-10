/*
Linear_Array_Sensor_Subpixel_Visualizer.pde, a demo of subpixel resolution shadow position measurement and visualization,
using a TSL1402R or TSL1410R linear photodiode array via serial port, or synthesized waveforms.

Created by Douglas Mayhew, November 20, 2016.
Released into the public domain, except:
 * The function, 'makeGaussKernel1d' is made available as part of the book 
 * "Digital Image * Processing - An Algorithmic Introduction using Java" by Wilhelm Burger
 * and Mark J. Burge, Copyright (C) 2005-2008 Springer-Verlag Berlin, Heidelberg, New York.
 * Note that this code comes with absolutely no warranty of any kind.
 * See http://www.imagingbook.com for details and licensing conditions. 

See: https://github.com/Mr-Mayhem/DSP_Snippets_For_Processing

Convolution loop code originally from //http://www.dspguide.com/ch6/3.htm
translated into Processing (java) by Douglas Mayhew

 * PanZoomController
 * @author Bohumir Zamecnik, modified by Doug Mayhew Dec 7, 2016
 * @license MIT
 * 
 * Inspired by "Pan And Zoom" by Dan Thompson, licensed under Creative Commons

 For more info on 3 point quadratic interpolation, see the subpixel edge finding method described in F. Devernay,
 A Non-Maxima Suppression Method for Edge Detection with Sub-Pixel Accuracy
 RR 2724, INRIA, nov. 1995
 http://dev.ipol.im/~morel/Dossier_MVA_2011_Cours_Transparents_Documents/2011_Cours1_Document1_1995-devernay--a-non-maxima-suppression-method-for-edge-detection-with-sub-pixel-accuracy.pdf

 quadratic interpolation subpixel code is my rework of many 'remixes' of the 
 Filament Width Sensor Prototype by flipper, as well as my own ideas to show the inner workings via graphics.
 I also added center position code, as all the filament width sensor projects seemed to only output the width 
 of the shadow.
 
 see Filament Width Sensor Prototype by flipper:
 https://www.thingiverse.com/thing:454584
 
 Another example filament width sensor with quadratic interpolation subpixel code is the "Zabe Width Sensor"
 see Filament Width Sensor - TSL1402R + Arduino Mega (Work-in-progress):
 https://www.thingiverse.com/thing:668377

 This sketch is able to run the subpixel position code against various data sources. 
 The sketch can synthesize some input data like square impulses, to verify that the output is 
 doing what it should. It also works with live sensor data from a TSL1402R or TSL1410R linear photodiode array, 
 arriving via USB serial port. To do this,
 see my 2 projects:
 
 Read-TSL1402R-Optical-Sensor-using-Teensy-3.x
 https://github.com/Mr-Mayhem/Read-TSL1402R-Optical-Sensor-using-Teensy-3.x
 
 and...
 
 Read-TSL1410R-Optical-Sensor-using-Teensy-3.x
 https://github.com/Mr-Mayhem/Read-TSL1410R-Optical-Sensor-using-Teensy-3.x
 
 This is a work in progress, but the subpixel code works nicely, and looks like it is proper.
 If you find any bugs, let me know via github or the Teensy forums in the following thread:
 https://forum.pjrc.com/threads/39376-New-library-and-example-Read-TSL1410R-Optical-Sensor-using-Teensy-3-x
 
 We still have some more refactoring and features yet to apply. I want to add:
 windowing and thresholding to reduce the workload of processing all data to processing only some data
 interpolation is not yet in this one.
 
 My update goals:
 1. Send shadow position and width instead of raw data, which is slower.
 2. Send a windowed section containing only the interesting data, rather than all the data.
 3. Auto-Calibration using drill bits, dowel pins, etc.
 4. Multiple angles of led lights shining on the target, so multiple exposures may be compared 
    for additional subpixel accuracy
 5. Add data window zoom and scrolling ***(Done!)***
 6. Add measurement history display
 7. Bringing the core of the position and subpixel code into Arduino for Teensy 3.6
*/
// ==============================================================================================
// imports:

import processing.serial.*;

// ==============================================================================================
// colors

color COLOR_ORIGINAL_DATA = color(255);
color COLOR_KERNEL_DATA = color(255, 255, 0);
color COLOR_FIRST_DIFFERENCE_OF_OUTPUT = color(0, 255, 0);
color COLOR_OUTPUT_DATA = color(255, 0, 255);
color COLOR_EDGES = color(0, 255, 0);
color COLOR_TAIL = color(0, 255, 255);
// ==============================================================================================
// Constants:
// the number of bits data values consist of
final int ADC_BIT_DEPTH = 12;

// this value is 4095 for 12 bits
final int HIGHEST_ADC_VALUE = int(pow(2.0, float(ADC_BIT_DEPTH))-1); 

// unique byte used to sync the filling of byteArray to the incoming serial stream
final int PREFIX = 0xFF;
// ==============================================================================================
// Arrays:

byte[] byteArray = new byte[0];      // array of raw serial data bytes
int[] input = new int[0];            // array for input signal
float[] kernel = new float[0];       // array for impulse response, or kernel
float[] output = new float[0];       // array for output signal
float[] output2 = new float[0];      // array for output signal

// Global Variables:
int signalSource;                    // selects a signal data source
int kernelSource;                    // selects a kernel
int SENSOR_PIXELS;                   // number of discrete values in the input array, 1 per linear array sensor pixel
int N_BYTES_PER_SENSOR_FRAME;        // we use 2 bytes to represent each sensor pixel
int N_BYTES_PER_SENSOR_FRAME_PLUS1;  // the data bytes + the PREFIX byte
int SCREEN_HEIGHT;                   // scales screen height relative to highest data value
int HALF_SCREEN_HEIGHT;              // half the screen height, reduces division math work because it is used alot
int OUTPUT_DATA_LENGTH;              // number of discrete values in the output array, set in setup()
  
int KERNEL_LENGTH;                   // number of discrete values in the kernel array, set in setup() 
int KERNEL_LENGTH_MINUS1;            // kernel length minus 1, used to reduce math in loops
int HALF_KERNEL_LENGTH;              // Half the kernel length, used to correct convoltion phase shift
int kernelDrawYOffset;               // height above bottom of screen to draw the kernel data points
  
int markSize;                        // diameter of drawn subpixel marker circles
int bytesRead;                       // number of bytes actually read out from the serial buffer
int availableBytesDraw;              // used to show the number of bytes present in the serial buffer
int subpixelMarkerLen;               // length of vertical lines which indicate subpixel peaks and shadow center location

float gaussianKernelSigma;           // input to kernel creation function, controls spreading of gaussian kernel
float loGKernelSigma;                // input to kernel creation function, controls spreading of loG kernel
float kernelMultiplier;              // multiplies the plotted y values of the kernel, for greater visibility since they are small
float noiseInput;                    // used for generating smooth noise for original data; lower values are smoother noise
float noiseIncrement;                // the increment of change of the noise input

// used to count sensor data frames
int chartRedraws = 0;

// width
int SCREEN_WIDTH;                    // screen width
int HALF_SCREEN_WIDTH;               // half the screen width, reduces division math work because it is used alot

// ==============================================================================================
// Set Objects
Serial myPort;       // One Serial object, receives serial port data from Teensy 3.6 running sensor driver sketch
dataPlot DP1;        // One dataPlot object, handles plotting data with mouse sliding and zooming ability
SignalGenerator SG1; // Creates input signals for the system to work on
KernelGenerator KG1; // Creates a kernel and saves it's data into an array
// ==============================================================================================

void setup() {
// ==============================================================================================
  // Set the data & screen scaling:
  // You are encouraged to adjust these, especially to 'zoom in' to the shadow location see the subpixel details better.
  
  // sets screen height relative to the highest ADC value, greater values increases screen height
  SCREEN_HEIGHT = int(HIGHEST_ADC_VALUE * 0.25); 
  
  // leave alone! Used in many places to center data at middle height
  HALF_SCREEN_HEIGHT = SCREEN_HEIGHT / 2;
  
  // sets height deviation of vertical lines from center height, indicates subpixel peaks and shadow center location
  subpixelMarkerLen = int(SCREEN_HEIGHT * 0.01);  
                      
  // height above bottom of screen to draw the kernel data points                                      
  kernelDrawYOffset = 75;
  
  // diameter of drawn subpixel marker circles
  markSize = 3;
  
  // input to kernel creation function, controls spreading of gaussian kernel
  gaussianKernelSigma = 1.6; 
  
  // input to kernel creation function, controls spreading of loG kernel
  loGKernelSigma = 1.0; 
  
  // multiplies the plotted y values of the kernel, for greater visibility since they are small
  kernelMultiplier = 100.0;

  // used for generating smooth noise for original data; lower values are smoother noise
  noiseInput = 0.05;

  // the increment of change of the noise input
  noiseIncrement = noiseInput;
  
  // Choose a kernel source: =====================================================================
  kernelSource = 0;
  // Create a kernelGenerator object, which creates a kernel and saves it's data into an array
  KG1 = new KernelGenerator(kernelSource);
  
  // Choose a signal source :=====================================================================
  // You are encouraged to try different signal sources, to see how the subpixel code behaves with nearly perfect waveforms
  signalSource = 3;
  // Create a dataPlot object, which plots data and provides mouse sliding and zooming ability
  SG1 = new SignalGenerator(signalSource);
  
  println("SENSOR_PIXELS = " + SENSOR_PIXELS);
  
  // number of discrete values in the output array
  OUTPUT_DATA_LENGTH = SENSOR_PIXELS + KERNEL_LENGTH-1;
  println("OUTPUT_DATA_LENGTH = " + OUTPUT_DATA_LENGTH);
  
  // arrays for output signals, get resized after kernel size is known
  output = new float[OUTPUT_DATA_LENGTH];
  output2 = new float[OUTPUT_DATA_LENGTH];
  
  // the data length times the number of pixels per data point
  SCREEN_WIDTH = 1024;//OUTPUT_DATA_LENGTH * SCALE_X;
  HALF_SCREEN_WIDTH = SCREEN_WIDTH / 2;
  
  // set the screen dimensions
  surface.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
  background(0);
  
  // Create the dataPlot object, which handles plotting data with mouse sliding and zooming ability
  DP1 = new dataPlot(this, 0, 0, SCREEN_WIDTH, HALF_SCREEN_HEIGHT, SENSOR_PIXELS);
  
  // set framerate() a little above where increases don't speed it up much.
  // Also note, for highest speed, comment out drawing plots you don't care about.
  frameRate(200); 
  
  SG1.resetData();
  
  println("SCREEN_WIDTH: " + SCREEN_WIDTH);
  println("SCREEN_HEIGHT: " + SCREEN_HEIGHT);
  
  if (signalSource == 3){
    noLoop();
    // Set up serial connection
    myPort = new Serial(this, "COM5", 12500000);
    // the serial port will buffer until prefix (unique byte that equals 255) and then fire serialEvent()
    myPort.bufferUntil(PREFIX);
  }
}

void serialEvent(Serial p) { 
  // copy one complete sensor frame of data, plus the prefix byte, into byteArray[]
  bytesRead = p.readBytes(byteArray);
  redraw();
}
  
void draw() {

  chartRedraws++;

  if (chartRedraws >= 60) {
     chartRedraws = 0;
   // save a sensor data frame to a text file every 60 sensor frames
   //String[] stringArray = new String[SENSOR_PIXELS];
   //for(outerPtrX=0; outerPtrX < SENSOR_PIXELS; outerPtrX++) { 
   //   stringArray[outerPtrX] = str(output[outerPtrX]);
   //}
   //   saveStrings("Pixel_Values.txt", stringArray);
  }
  background(0);
  fill(255);
  
  // Counts 1 to 60 and repeats
  text(chartRedraws, 10, 50); //<>//

  // Plot the Data
   DP1.display();
   SG1.zeroOutputData();
}

void keyPressed() {
  DP1.keyPressed();
}

void mouseDragged() {
  DP1.mouseDragged();
}

void mouseWheel(MouseEvent event) {
  DP1.mouseWheel(-event.getCount()); // note the minus sign (-) inverts the mouse wheel output direction
} //<>//