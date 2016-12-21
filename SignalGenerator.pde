class SignalGenerator {
  // by Douglas Mayhew 12/1/2016
  // This class draws the legend

  float noiseInput;                    // used for generating smooth noise for original data; lower values are smoother noise
  float noiseIncrement;                // the increment of change of the noise input

  SignalGenerator () {

    // used for generating smooth noise for original data; lower values are smoother noise
    noiseInput = 0.2;

    // the increment of change of the noise input
    noiseIncrement = noiseInput;
  }

  int[] signalGeneratorOutput(int signalSource, int dataLen, int multY) {

    int[] sgOutput = new int[0];

    switch (signalSource) {
    case 0: 
      // hard-coded sensor data containing a shadow edge profile
      sgOutput = SG1.setHardCodedSensorData(); 
      SENSOR_PIXELS = sgOutput.length;
      break;
    case 1:
      // a single adjustable step impulse, (square pos or neg pulse) 
      // useful for verifying the kernel is doing what it should.

      sgOutput = setInputSingleImpulse(dataLen, multY, 16, false);
      SENSOR_PIXELS = sgOutput.length;
      break;
    case 2: 
      // an adjustable square wave
      sgOutput = setInputSquareWave(dataLen, 40, multY);
      SENSOR_PIXELS = sgOutput.length;
      break;
    case 3: 
      // Serial Data from Teensy 3.6 driving TSL1402R or TSL1410R linear photodiode array
      SENSOR_PIXELS = 1280; // Number of pixel values, 256 for TSL1402R sensor, and 1280 for TSL1410R sensor
      N_BYTES_PER_SENSOR_FRAME = SENSOR_PIXELS * 2; // we use 2 bytes to represent each sensor pixel
      N_BYTES_PER_SENSOR_FRAME_PLUS1 = N_BYTES_PER_SENSOR_FRAME + 1; // the data bytes + PREFIX byte
      byteArray = new byte[N_BYTES_PER_SENSOR_FRAME_PLUS1]; // array of raw serial data bytes
      sgOutput = new int[SENSOR_PIXELS];
      break;
    case 4: 
      // perlin noise
      sgOutput = perlinNoise(multY, dataLen);
      SENSOR_PIXELS = sgOutput.length;
      break;
    case 5:
      prepVideoMode();
    break;
    default:
      // hard-coded sensor data containing a shadow edge profile
      sgOutput = SG1.setHardCodedSensorData(); 
      SENSOR_PIXELS = sgOutput.length;
    }
    println("SENSOR_PIXELS = " + SENSOR_PIXELS);
    // number of discrete values in the output array
    return sgOutput;
  }

  int[] perlinNoise(int multY, int dataLen) {
    int[] rdOut = new int[dataLen];
    for (int c = 0; c < dataLen; c++) {
      // adjust smoothness with noise input
      noiseInput = noiseInput + noiseIncrement; 
      if (noiseInput > 100) {
        noiseInput = noiseIncrement;
      }
      // perlin noise
      rdOut[c] = int(map(noise(noiseInput), 0, 1, 0, multY));  
      //println (noise(noiseInput));
    }
    return rdOut;
  }

  int[] setHardCodedSensorData() {

    int len = 60;

    int[] data = new int[len];

    data[0] = 1000;
    data[1] = 1000;
    data[2] = 1000;
    data[3] = 1000;
    data[4] = 1000;
    data[5] = 1000;
    data[6] = 1000;
    data[7] = 1000;
    data[8] = 1000;
    data[9] = 1000;
    data[10] = 1000;
    data[11] = 1000;
    data[12] = 1000;
    data[13] = 1000;
    data[14] = 1000;
    data[15] = 1000;
    data[16] = 1000;
    data[17] = 1000;
    data[18] = 1000;
    data[19] = 1000;
    data[20] = 1000;
    data[21] = 1000;
    data[22] = 1000;
    data[23] = 1000;
    data[24] = 1000;
    data[25] = 200;
    data[26] = 200;
    data[27] = 200;
    data[28] = 200;
    data[29] = 200;
    data[30] = 200;
    data[31] = 200;
    data[32] = 200;
    data[33] = 200;
    data[34] = 200;
    data[35] = 200;
    data[36] = 1000;
    data[37] = 1000;
    data[38] = 1000;
    data[39] = 1000;
    data[40] = 1000;
    data[41] = 1000;
    data[42] = 1000;
    data[43] = 1000;
    data[44] = 1000;
    data[45] = 1000;
    data[46] = 1000;
    data[47] = 1000;
    data[48] = 1000;
    data[49] = 1000;
    data[50] = 1000;
    data[51] = 1000;
    data[52] = 1000;
    data[53] = 1000;
    data[54] = 1000;
    data[55] = 1000;
    data[56] = 1000;
    data[57] = 1000;
    data[58] = 1000;
    data[59] = 1000;

    return data;
  }

  int[] setInputSingleImpulse(int dataLength, int multY, int pulseWidth, boolean positivePolarity) {

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
      data[c] = 0;
    }

    // pulse
    if (positivePolarity) {
      for (int c = startPos; c < stopPos; c++) {
        data[c] = multY;
      }
    } else {
      for (int c = startPos; c < stopPos; c++) {
        data[c] = -multY;
      }
    }

    // tail
    for (int c = stopPos; c < dataLength; c++) {
      data[c] = 0;
    }
    return data;
  }

  int[] setInputSquareWave(int dataLength, int wavelength, int multY) {

    double sinPoint = 0;
    double squarePoint = 0;
    int data[] = new int[dataLength];

    for (int i = 0; i < data.length; i++)
    {
      sinPoint = Math.sin(2 * Math.PI * i/wavelength);
      squarePoint = Math.signum(sinPoint);
      //println(squarePoint);
      data[i] =(int)(squarePoint) * multY;
    }
    return data;
  }
}