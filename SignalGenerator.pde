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
      rdOut[c] = int(map(noise(noiseInput), 0, 1, 0, 1 * multY));  
      //println (noise(noiseInput));
    }
    return rdOut;
  }

  int[] setHardCodedSensorData() {

    int len = 60;

    int[] data = new int[len];

    data[0] = 2000;
    data[1] = 2000;
    data[2] = 2000;
    data[3] = 2000;
    data[4] = 2000;
    data[5] = 2000;
    data[6] = 2000;
    data[7] = 2000;
    data[8] = 2000;
    data[9] = 2000;
    data[10] = 2000;
    data[11] = 2000;
    data[12] = 2000;
    data[13] = 2000;
    data[14] = 2000;
    data[15] = 2000;
    data[16] = 2000;
    data[17] = 2000;
    data[18] = 2000;
    data[19] = 2000;
    data[20] = 2000;
    data[21] = 2000;
    data[22] = 2000;
    data[23] = 2000;
    data[24] = 2000;
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
    data[36] = 2000;
    data[37] = 2000;
    data[38] = 2000;
    data[39] = 2000;
    data[40] = 2000;
    data[41] = 2000;
    data[42] = 2000;
    data[43] = 2000;
    data[44] = 2000;
    data[45] = 2000;
    data[46] = 2000;
    data[47] = 2000;
    data[48] = 2000;
    data[49] = 2000;
    data[50] = 2000;
    data[51] = 2000;
    data[52] = 2000;
    data[53] = 2000;
    data[54] = 2000;
    data[55] = 2000;
    data[56] = 2000;
    data[57] = 2000;
    data[58] = 2000;
    data[59] = 2000;

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
        data[c] = 1 * multY;
      }
    } else {
      for (int c = startPos; c < stopPos; c++) {
        data[c] = -1 * multY;
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