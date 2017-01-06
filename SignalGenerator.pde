class SignalGenerator {
  // by Douglas Mayhew 12/1/2016
  // This class draws the legend

  int adcBitDepth;        // number of bits used to represent the signal
  int highestADCValue;    // signal value ceiling, 2 to the power of bitDepth -1
  int signalAmplitude;    // Amplitude or total height of the waves

  float noiseInput;       // used for generating smooth noise for original data; lower values produce smoother noise
  float noiseIncrement;   // the increment of change of the noise input

  // ========== Kernel Generation Variables (kernel generator moved to this class to reduce code redundancy) ===========
  double kSigma;          // input to dynamically created kernel function, controls sigma or 'spread' of gaussian kernel
  double kSigmaDefault;   // the default value is set on class init

  double kSigmaGaussianMin;
  double kSigmaGaussianMax;

  double kSigmaLOGMin;
  double kSigmaLOGMax;

  // a menu of various one dimensional kernels, example: kernel = setArray(gaussian); 
  float [] gaussian = {0.0048150257, 0.028716037, 0.10281857, 0.22102419, 
    0.28525233, 0.22102419, 0.10281857, 0.028716037, 0.0048150257};
  // float [] sorbel = {1, 0, -1};
  // float [] gaussianLaplacian = {-7.474675E-4, -0.0123763615, -0.04307856, 0.09653235, 
  // 0.31830987, 0.09653235, -0.04307856, -0.0123763615, -7.474675E-4};
  // float [] laplacian = {1, -2, 1}; 
  // ========== End kernel generation variables ======================================================================

  private PApplet p; // parent object

  SignalGenerator (PApplet p, double defaultKernelSigma) {

    this.p = p;
    // used for generating smooth noise for original data; lower values are smoother noise
    noiseInput = 0.2;

    // the increment of change of the noise input
    noiseIncrement = noiseInput;

    // Sigma is the input to dynamic kernel creation functions, it controls the 'spreading'
    // of the kernel. This is an important adjustment for subpixel accuracy.
    // If sigma is set too low, the noise creeps in and the peaks are not rounded enough 
    // for good subpixel results.
    // If sigma is set too high, the difference peaks get smoothed out and flattend too much,
    // and accuracy suffers from over-spreading of the edges.
    // Until an automated method gets put in place to find the ideal kernel sigma value, just
    // simply experiment with different values under controlled conditions, and compare results.

    kSigmaGaussianMin = 0.5;
    kSigmaGaussianMax = 8;

    kSigmaLOGMin = 0.75;
    kSigmaLOGMax = 1.75;

    kSigmaDefault = defaultKernelSigma;
    kSigma = defaultKernelSigma;
  }

  int[] signalGeneratorOutput(int signalSource, int dataLen, int bitDepth, int waveLength) {

    int[] sgOutput = new int[0];

    // the number of bits data values consist of
    adcBitDepth = bitDepth;

    // 2 to the power of bitDepth -1
    highestADCValue = int(pow(2.0, float(adcBitDepth))-1); 
    signalAmplitude = highestADCValue /2;
    println("Signal Generator signalAmplitude = " + signalAmplitude);
    
    switch (signalSource) {
    case 0: 
      // hard-coded sensor data containing a shadow edge profile
      sgOutput = SG1.hardCodedSensorData(); 
      SENSOR_PIXELS = sgOutput.length;
      break;
    case 1:
      // a single adjustable step impulse, (square pos or neg pulse) 
      // useful for verifying the kernel is doing what it should.

      sgOutput = Impulse(dataLen, waveLength, signalAmplitude);
      SENSOR_PIXELS = sgOutput.length;
      break;
    case 2: 
      // an adjustable positive square wave
      sgOutput = positiveSquareWave(dataLen, waveLength, signalAmplitude);
      SENSOR_PIXELS = sgOutput.length;
      break;
    case 3: 
      // Serial Data from Teensy 3.6 driving TSL1402R or TSL1410R linear photodiode array
      SENSOR_PIXELS = 1280; // Number of pixel values, 256 for TSL1402R sensor, and 1280 for TSL1410R sensor
      N_BYTES_PER_SENSOR_FRAME = SENSOR_PIXELS * 2;                    // we use 2 bytes to represent each sensor pixel
      N_BYTES_PER_SENSOR_FRAME_PLUS1 = N_BYTES_PER_SENSOR_FRAME + 1;   // the data bytes + PREFIX byte
      byteArray = new byte[N_BYTES_PER_SENSOR_FRAME_PLUS1];            // init the array for raw serial data bytes
      sgOutput = new int[SENSOR_PIXELS];                               // init the signal generator array
      break;
    case 4: 
      // perlin noise
      sgOutput = perlinNoise(dataLen, signalAmplitude);
      SENSOR_PIXELS = sgOutput.length;
      break;
    case 5:
      prepVideoMode();
      break;
    case 6:
      // an adjustable sine wave
      sgOutput = positiveSineWave(dataLen, waveLength, signalAmplitude);
      SENSOR_PIXELS = sgOutput.length;
      break;
    default:
      // hard-coded sensor data containing a shadow edge profile
      sgOutput = SG1.hardCodedSensorData(); 
      SENSOR_PIXELS = sgOutput.length;
    }
    println("SENSOR_PIXELS = " + SENSOR_PIXELS);
    // number of discrete values in the output array
    return sgOutput;
  }

  int[] perlinNoise(int dataLen, int amplitude) {
    int[] rdOut = new int[dataLen];
    for (int c = 0; c < dataLen; c++) {
      // adjust smoothness with noise input
      noiseInput = noiseInput + noiseIncrement; 
      if (noiseInput > 100) {
        noiseInput = noiseIncrement;
      }
      // perlin noise
      rdOut[c] = int(map(noise(noiseInput), 0, 1, 0, amplitude));  
      //println (noise(noiseInput));
    }
    return rdOut;
  }

  int[] hardCodedSensorData() {

    int len = 64;

    int[] data = new int[len];

    data[0] = 1500;
    data[1] = 1500;
    data[2] = 1500;
    data[3] = 1500;
    data[4] = 1500;
    data[5] = 1500;
    data[6] = 1500;
    data[7] = 1500;
    data[8] = 1500;
    data[9] = 1500;
    data[10] = 1500;
    data[11] = 1500;
    data[12] = 1500;
    data[13] = 1500;
    data[14] = 1500;
    data[15] = 1500;
    data[16] = 1500;
    data[17] = 1500;
    data[18] = 1500;
    data[19] = 1500;
    data[20] = 1500;
    data[21] = 1500;
    data[22] = 1500;
    data[23] = 1500;
    data[24] = 1500;
    data[25] = 1500; // left edge   25.5
    data[26] = 200;  // 5 left edge 25.5
    data[27] = 200;  // 4
    data[28] = 200;  // 3
    data[29] = 200;  // 2
    data[30] = 200;  // 1
    data[31] = 200;  // 0 center (31 is the 32nd element because we started at zero), 11 pixels wide
    data[32] = 200;  // 1
    data[33] = 200;  // 2
    data[34] = 200;  // 3
    data[35] = 200;  // 4
    data[36] = 200;  // 5 right edge 36.5
    data[37] = 1500; // right edge   36.5
    data[38] = 1500;
    data[39] = 1500;
    data[40] = 1500;
    data[41] = 1500;
    data[42] = 1500;
    data[43] = 1500;
    data[44] = 1500;
    data[45] = 1500;
    data[46] = 1500;
    data[47] = 1500;
    data[48] = 1500;
    data[49] = 1500;
    data[50] = 1500;
    data[51] = 1500;
    data[52] = 1500;
    data[53] = 1500;
    data[54] = 1500;
    data[55] = 1500;
    data[56] = 1500;
    data[57] = 1500;
    data[58] = 1500;
    data[59] = 1500;
    data[60] = 1500;
    data[61] = 1500;
    data[62] = 1500;
    data[63] = 1500;
    return data;
  }

  int[] Impulse(int dataLength, int pulseWidth, int amplitude) {

    if (pulseWidth < 2) {
      pulseWidth = 2;
    }

    int center = (dataLength / 2);
    int halfPositives = pulseWidth / 2;
    int startPos = center - halfPositives;
    int stopPos = center + halfPositives;

    int[] data = new int[dataLength];

    // head
    for (int c = 0; c < dataLength; c++) {
      data[c] = amplitude;
    }

    // pulse
    for (int c = startPos; c < stopPos; c++) {
      data[c] = 0;
    }

    // tail
    for (int c = stopPos; c < dataLength; c++) {
      data[c] = amplitude;
    }
    return data;
  }

  int[] positiveSquareWave(int numSamples, float wavelength, int amplitude) {

    int data[] = new int[numSamples];
    float dutyCycle = 0.5;
    double scaler = 1/wavelength;
    double shift = dutyCycle / 2;

    for (int i = 0; i < numSamples; i++) {
      float val = (i * scaler + shift) % 1 < dutyCycle ? 1 : 0;
      data[i] = int(val * amplitude);
      //println("data[" + i + "]  = " + data[i]);
    }
    return data;
  }

  int[] positiveSineWave(int dataLength, int wavelength, int amplitude) {
    
    double sinPoint = 0;
    int data[] = new int[dataLength];

    for (int i = 0; i < data.length; i++)
    {
      sinPoint = Math.sin((TWO_PI * i) / wavelength);
      data[i] = (int)((((sinPoint) * 0.5) + 0.5)*amplitude);
      //println("data[" + i + "]  = " + data[i]);
    }
    return data;
  }

  float[] oneCycleSineWaveFloats(int dataLength) {

    double sinPoint = 0;
    float data[] = new float[dataLength];

    for (int i = 0; i < data.length; i++)
    {
      sinPoint = Math.sin((TWO_PI * i) / dataLength);
      data[i] = (float)((sinPoint) * 0.5) + 0.5;
      //println("data[" + i + "]  = " + data[i]);
    }
    return data;
  }

  public void mouseWheel(int step) {
    kSigma += (step * 0.01);

    if (kernelSource == 0) {
      kSigma = constrainDbl(kSigma, kSigmaGaussianMin, kSigmaGaussianMax);
      kernel = makeGaussKernel1d(kSigma);
    } else if (kernelSource == 2) {
      kSigma = constrainDbl(kSigma, kSigmaLOGMin, kSigmaLOGMax);
      kernel = createLoGKernal1d(kSigma);
    }
  }

  double constrainDbl(double value, double min, Double max) {
    double retVal;
    if (value < min) {
      retVal = min;
    } else if (value > max) {
      retVal = max;
    } else {
      retVal = value;
    }
    return retVal;
  }


  float [] setKernelSource(int kernelSource) {

    switch (kernelSource) {
    case 0:
      // a dynamically created gaussian bell curve kernel, adjustable with mouse
      kernel = makeGaussKernel1d(kSigma); 
      break;
    case 1:
      // a hard-coded gaussian kernel, is NOT adjustable with mouse
      kSigma = 1.4;
      kernel = setKernelArray(gaussian);
      break;
    case 2:
      // a loGKernelSigma kernel, adjustable with mouse
      kernel = createLoGKernal1d(kSigma);
      break;
    default:
      // a hard-coded gaussian kernel, is NOT adjustable with mouse
      kSigma = 1.4;
      kernel = setKernelArray(gaussian);
    }
    return kernel;
  }

  float [] setKernelArray(float [] inArray) {

    float[] kernel = new float[inArray.length]; // set to an odd value for an even integer phase offset
    kernel = inArray;

    for (int i = 0; i < kernel.length; i++) {
      //println("setArray kernel[" + i + "] = " + kernel[i]);
    }

    KERNEL_LENGTH = kernel.length;                 // always odd
    KERNEL_LENGTH_MINUS1 = KERNEL_LENGTH - 1;      // always even
    HALF_KERNEL_LENGTH = KERNEL_LENGTH_MINUS1 / 2; // always even divided by 2 = even halves
    //println("KERNEL_LENGTH: " + KERNEL_LENGTH);

    return kernel;
  }

  float[] makeGaussKernel1d(double sigma) {
    /**
     * This sample code is made available as part of the book "Digital Image
     * Processing - An Algorithmic Introduction using Java" by Wilhelm Burger
     * and Mark J. Burge, Copyright (C) 2005-2008 Springer-Verlag Berlin, 
     * Heidelberg, New York.
     * Note that this code comes with absolutely no warranty of any kind.
     * See http://www.imagingbook.com for details and licensing conditions.
     * 
     * Date: 2007/11/10
     
     kernel height rescaling (which normalizes all values to sum to 1) code 
     added here in Linerar Array Subpixel Visualizer by 
     Doug Mayhew, November 20 2016
     
     code found also at:
     https://github.com/biometrics/imagingbook/blob/master/src/gauss/GaussKernel1d.java
     */

    // scaling variables
    double sum = 0;
    double scale = 1;

    // make 1D Gauss filter kernel large enough
    // to avoid truncation effects (too small in ImageJ!) 
    int center = (int) (3.0 * sigma);
    double[] kerneldb = new double[2 * center + 1]; // odd size
    float[] kernelfl = new float[2 * center + 1];   // odd size
    double sigma2 = sigma * sigma;

    for (int i=0; i<kerneldb.length; i++) {
      double r = center - i;
      kerneldb[i] =  (double) Math.exp(-0.5 * (r*r) / sigma2);
      sum += kerneldb[i];
      //println("kernel[" + i + "] = " + kerneldb[i]);
    }

    if (sum!= 0.0) {
      scale = 1.0 / sum;
    } else {
      scale = 1;
    }

    //println("gaussian kernel scale = " + scale); // print the scale.
    sum = 0; // clear the previous sum
    // scale the kernel values
    for (int i=0; i < kerneldb.length; i++) {
      kernelfl[i] = (float)(kerneldb[i] * scale);
      sum += kernelfl[i];
      // print the kernel value.
      //println("scaled gaussian kernel[" + i + "]:" + kernelfl[i]);
    }

    if (sum!= 0.0) {
      scale = 1.0 / sum;
    } else {
      scale = 1;
    }

    // print the new scale. Should be very close to 1.
    //println("gaussian kernel new scale = " + scale);

    KERNEL_LENGTH = kernelfl.length;                 // always odd
    KERNEL_LENGTH_MINUS1 = KERNEL_LENGTH - 1;        // always even
    HALF_KERNEL_LENGTH = KERNEL_LENGTH_MINUS1 / 2;   // always even divided by 2 = even halves
    //println("KERNEL_LENGTH = " + KERNEL_LENGTH);
    return kernelfl;
  }

  float[] createLoGKernal1d(double deviation) {

    int center = (int) (5 * deviation);
    int kSize = 2 * center + 1; // set to an odd value for an even integer phase offset
    // using a double internally for greater precision
    double[] kernel = new double[kSize];
    // using a double for the final return value
    float[] fkernel = new float [kSize];  // double version for return value
    double first = 1.0 / (Math.PI * Math.pow(deviation, 4.0));
    double second = 2.0 * Math.pow(deviation, 2.0);
    double third;
    int r = kSize / 2;
    int x;

    for (int i = -r; i <= r; i++) {
      x = i + r;
      third = Math.pow(i, 2.0) / second;
      kernel[x] = (double) (first * (1 - third) * Math.exp(-third));
      fkernel[x] = (float) kernel[x];
      //println("LoG kernel[" + x + "] = " + fkernel[x]);
    }
    KERNEL_LENGTH = fkernel.length;                // always odd
    KERNEL_LENGTH_MINUS1 = KERNEL_LENGTH - 1;      // always even
    HALF_KERNEL_LENGTH = KERNEL_LENGTH_MINUS1 / 2; // always even divided by 2 = even halves
    //println("KERNEL_LENGTH: " + KERNEL_LENGTH);
    return fkernel;
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
      video = new Capture(p, 640, 480);
      //video = new Capture(this, cameras[0]);
      // Start capturing the images from the camera
      video.start();
      SENSOR_PIXELS = video.width;
      videoArray = new int[SENSOR_PIXELS];
      //surface.setSize(video.width, video.height);
    }
  }
}