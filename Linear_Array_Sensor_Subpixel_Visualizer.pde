/*
 Linear_Array_Sensor_Subpixel_Visualizer.pde, Subpixel resolution shadow position measurement and visualization,
 using a TSL1402R or TSL1410R linear photodiode array via serial port, video line-grab, or internally generated 
 waveforms.
 
 Created by Douglas Mayhew, November 20, 2016.
 
 Plots sensor or simulated data, convolves it to smooth it using an adjustable gaussian kernel, 
 plots the convolution output and the first differences of that output, and finds all shadows 
 or simulated shadows and reports their position with subpixel accuracy using quadratic interpolation.
   
 The shadow positions reported in the text display assume the first sensor pixel is pixel number 1.
 Shadows create one negative peak followed by one positive peak in the 1st difference plot.
 Simple mods are coming shortly for use in finding spectra peaks or laser peaks, etc, which are single peak,
 not double-peaked like the shadows, so need a slightly different peak finder. 

 Released into the public domain, except:
 * The function, 'makeGaussKernel1d' is made available as part of the book 
 * "Digital Image * Processing - An Algorithmic Introduction using Java" by Wilhelm Burger
 * and Mark J. Burge, Copyright (C) 2005-2008 Springer-Verlag Berlin, Heidelberg, New York.
 * Note that this code comes with absolutely no warranty of any kind.
 * See http://www.imagingbook.com for details and licensing conditions. 
 
 See: https://github.com/Mr-Mayhem/DSP_Snippets_For_Processing
 
 * PanZoomController
 * @author Bohumir Zamecnik, modified by Doug Mayhew Dec 7, 2016
 * @license MIT
 * 
 * Inspired by "Pan And Zoom" by Dan Thompson, licensed under Creative Commons
 
 For more info on 3 point quadratic interpolation, see the subpixel edge finding method described in F. Devernay,
 A Non-Maxima Suppression Method for Edge Detection with Sub-Pixel Accuracy
 RR 2724, INRIA, nov. 1995
 http://dev.ipol.im/~morel/Dossier_MVA_2011_Cours_Transparents_Documents/2011_Cours1_Document1_1995-devernay--a-non-maxima-suppression-method-for-edge-detection-with-sub-pixel-accuracy.pdf
 
 The subpixel code has evolved quite a bit since I last first saw an example in a filiment width sensor:
 
 see Filament Width Sensor Prototype by flipper:
 https://www.thingiverse.com/thing:454584
 

 This sketch is able to run the subpixel position code against various data sources. 
 The sketch can synthesize test data like square impulses, to verify that the output is 
 reporting what it should and outputs are phased correctly relative to each other, 
 but this sketch is mainly concerned with displaying and measuring 
 shadow positions in live sensor serial data from a TSL1402R or TSL1410R linear photodiode array,
 or from a video camera line-grab across the middle of the video frame. 
 
 To feed this sketch with data from the TSL1402R or TSL1410R sensors, see my 2 related projects:
 
 Read-TSL1402R-Optical-Sensor-using-Teensy-3.x
 https://github.com/Mr-Mayhem/Read-TSL1402R-Optical-Sensor-using-Teensy-3.x
 
 and...
 
 Read-TSL1410R-Optical-Sensor-using-Teensy-3.x
 https://github.com/Mr-Mayhem/Read-TSL1410R-Optical-Sensor-using-Teensy-3.x
 
 This is a work in progress, but the subpixel code works nicely, and keeps evolving.
 I tried to keep it fast as possible. If you want higher speed, turn off the display of
 plots, and other unnecessary graphics. Also, the TSL1402R, being 1/5 the size of the TSL1410R, 
 is 5 times faster. So if you really don't need the 1280 pixel width of the TSL1410R, use the
 256 pixel TSL1402R. There are others in-between, but I haven't played with them yet, but
 converting the Teensy Arduino library and this sketch to differenct pixel counts is trivial, which is what
 I did to support the TSL1410R with it's own Teensy arduino library.
 
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
 for additional subpixel accuracy, or a faster solution - multiple slits casting shadows 
 and averaging the shadow subpixel positions.
 5. Add data window zoom and scrolling ***(Done!)***
 6. Add measurement waterfall history display  ***(Done!)***
 7. Bringing the core of the position and subpixel code into Arduino for Teensy 3.6
 8. data averaging two or more frames or sub-frames (windowed processing)  ***(Done, but commented out for speed,
    Also commented out because Teensy 3.6 has ADC averaging, so probably a redundant capability)***
 9. Collect and display unlimited number of shadows ***(Done!)*** Try a square wave or putting a comb over the 
    sensor with a light above.
 */
// ==============================================================================================
// imports:

import processing.serial.*;
import processing.video.*;

// ==============================================================================================
// Constants:

// unique byte used to sync the filling of byteArray to the incoming serial stream
final int PREFIX = 0xFF;
// ==============================================================================================
// Arrays:

byte[] byteArray = new byte[0];      // array of raw serial data bytes
int[] sigGenOutput = new int[0];     // array for signal generator output
float[] kernel = new float[0];       // array for impulse response, or kernel
int videoArray[] = new int[0];       // holds one row of video data, a row of integer pixels copied from the video image
float[] sineArray = new float[0];    // holds a one cycle sine wave, used to modulate Signal Generator output X axis
// ==============================================================================================
// Global Variables:

int HALF_SCREEN_HEIGHT;              // half the screen height, reduces division math work because it is used alot
int HALF_SCREEN_WIDTH;               // half the screen width, reduces division math work because it is used alot
int signalSource;                    // selects a signal data source
int kernelSource;                    // selects a kernel
int SENSOR_PIXELS;                   // number of discrete data values, 1 per sensor pixel
int N_BYTES_PER_SENSOR_FRAME;        // we use 2 bytes to represent each sensor pixel
int N_BYTES_PER_SENSOR_FRAME_PLUS1;  // the data bytes + the PREFIX byte
int KERNEL_LENGTH;                   // number of discrete values in the kernel array, set in setup() 
int KERNEL_LENGTH_MINUS1;            // kernel length minus 1, used to reduce math in loops
int HALF_KERNEL_LENGTH;              // Half the kernel length, used to correct convoltion phase shift
int bytesRead;                       // number of bytes actually read out from the serial buffer
int availableBytesDraw;              // used to show the number of bytes present in the serial buffer
int gtextSize;                       // sizes all text, consumed by this page, dataplot class, legend class
int chartRedraws = 0;                // used to count sensor data frames

// ==============================================================================================
// Set Objects

Serial myPort;       // One Serial object, receives serial port data from Teensy 3.6 running sensor driver sketch
dataPlot DP1;        // One dataPlot object, handles plotting data with mouse sliding and zooming ability
SignalGenerator SG1; // Creates artificial signals for the system to process and display for testing & experientation
Capture video;       // create video capture object named video
// ==============================================================================================

void setup() {
  // Set a size or fullScreen:
  //fullScreen();
  size(640, 480);
  //size(1280, 800);
  // Set the data & screen scaling:
  // You are encouraged to adjust these, especially to 'zoom in' to the shadow location see the subpixel details better.

  // leave alone! Used in many places to center data at center of screen, width-wise
  HALF_SCREEN_WIDTH = width / 2;

  // leave alone! Used in many places to center data at center of screen, height-wise
  HALF_SCREEN_HEIGHT = height / 2;

  // set the screen dimensions
  //surface.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
  gtextSize = 9; // sizes all text, consumed by this page, dataplot class, legend class to space text y using this value plus padding
  // set framerate() a little above where increases don't speed it up much.
  // Also note, for highest speed, comment out drawing plots you don't care about.
  frameRate(500);
  background(0);
  strokeWeight(1);
  textSize(gtextSize);
  println("SCREEN_WIDTH: " + width);
  println("SCREEN_HEIGHT: " + height);

  // ============================================================================================
  // 0 is default, dynamically created gaussian kernel
  kernelSource = 0; // <<< <<< Choose a kernel source (0 = dynamically created gaussian "bell curve"):

  // Create a kernelGenerator object, which creates a kernel and saves it's data into an array
  // 0: dynamically created gaussian kernel
  // 1: hard-coded gaussuan kernel (manually typed array values)
  // 2: laplacian of gaussian (LOG) kernel just to see what happens. Some laser subpixel papers like it, but experimental, not conventional;

  // ============================================================================================
  // You are encouraged to try different signal sources to feed the system

  signalSource = 2;  // <<< <<< Choose a signal source; 

  // 0: manually typed array data
  // 1: square impulse
  // 2: square wave 
  // 3: serial data from linear photodiode array sensor, use with sister Teensy 3.6 arduino sketch
  // 4: random perlin noise
  // 5: center height line grab from your video camera
  // 6: sine wave
  // 7: one cycle sine wave
  // =============================================================================================

  // Create a dataPlot object, which plots data and provides mouse sliding and zooming ability
  SG1 = new SignalGenerator(1.4);
  SG1.setKernelSource(kernelSource);
  sigGenOutput = SG1.signalGeneratorOutput(signalSource, 256, 1000); // data source, num of data points, height of peaks
  sineArray = SG1.oneCycleSineWaveFloats(256); // values used to move x to and fro as "modulation"

  // Create the dataPlot object, which handles plotting data with mouse sliding and zooming ability
  // dataStop set not past SENSOR_PIXELS, rather than SENSOR_PIXELS + KERNEL_LENGTH, to prevent convolution garbage at end 
  // from partial kernel immersion
  DP1 = new dataPlot(this, 0, 0, width, HALF_SCREEN_HEIGHT, SENSOR_PIXELS, gtextSize); 
  DP1.modulateX = true; // apply simulated shadow movement, half a pixel left and right in a sine wave motion
  DP1.diffThresholdY = 64; // absolute value 1st difference peaks must reach to be detected
  if (signalSource == 3) {
    noLoop();
    // Set up serial connection
    // Set to your Teensy COM port number to fix error, make sure it talks to Arduino software if stuck.
    println("List of Serial Ports:");
    printArray(Serial.list());
    println("End of Serial Port List");
    
    //Linux
    myPort = new Serial(this, "/dev/ttyACM0", 12500000);

    //Windows
    //myPort = new Serial(this, "COM5", 12500000);
    // the serial port will buffer until prefix (unique byte that equals 255) and then fire serialEvent()
    myPort.bufferUntil(PREFIX);
    myPort.clear(); // prevents bad sync glitch from happening, empties buffer on start
  }
  if (signalSource == 5) {
    noLoop();
    frameRate(120); // cheap cameras are 30, but we aim a little higher so internals are not 'lazy'
  }
}

void serialEvent(Serial p) { 
  // copy one complete sensor frame of data, plus the prefix byte, into byteArray[]
  // only enabled when signalSource is set to 3 (serial data), see above.
  bytesRead = p.readBytes(byteArray);
  redraw(); // fires the draw() function below. In cases where signalSource is not 3 (Serial Data), 
  // draw() fires automatically because we do not call noLoop()
}

void captureEvent(Capture video) {
  video.read();
  redraw();
}

void prepVideoMode() {
  String[] cameras = Capture.list();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
  } 
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");

    for (int i = 0; i < cameras.length; i++) {
      println(i + cameras[i]);
    }
    video = new Capture(this, 640, 480);
    //video = new Capture(this, cameras[0]);
    // Start capturing the images from the camera
    video.start();
    SENSOR_PIXELS = video.width;
    videoArray = new int[SENSOR_PIXELS];
    //surface.setSize(video.width, video.height);
  }
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

  // Plot the Data using the DataPlot object
  DP1.display();
}

void keyPressed() {
  DP1.keyPressed();
}

void mouseDragged() {
  DP1.mouseDragged();
}

void mouseWheel(MouseEvent event) {
  DP1.mouseWheel(-event.getCount()); // note the minus sign (-) inverts the mouse wheel output direction
}