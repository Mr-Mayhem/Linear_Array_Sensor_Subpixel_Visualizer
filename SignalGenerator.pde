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
  
  int[] signalGeneratorOutput(int signalSource, int dataLen, int multY){
    
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
        
        sgOutput = setInputSingleImpulse(dataLen, multY, 20, (KERNEL_LENGTH/2)+1, false);
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

  int[] perlinNoise(int multY, int dataLen){
    int[] rdOut = new int[dataLen];
    for (int c = 0; c < dataLen; c++) {
      // adjust smoothness with noise input
      noiseInput = noiseInput + noiseIncrement; 
      if(noiseInput > 100){
        noiseInput = noiseIncrement;
      }
      // perlin noise
      rdOut[c] = int(map(noise(noiseInput), 0, 1, 0, 1 * multY));  
      //println (noise(noiseInput));
     }
     return rdOut;
  }
  
  int[] setHardCodedSensorData(){
  
    int len = 70;
    
    int[] data = new int[len];
    
    data[0] = 3343;
    data[1] = 3305;
    data[2] = 3327;
    data[3] = 3388;
    data[4] = 3459;
    data[5] = 3429;
    data[6] = 3414;
    data[7] = 3425;
    data[8] = 3430;
    data[9] = 3425;
    data[10] = 3362;
    data[11] = 3317;
    data[12] = 3418;
    data[13] = 3402;
    data[14] = 3282;
    data[15] = 3370;
    data[16] = 3439;
    data[17] = 3373;
    data[18] = 3445;
    data[19] = 3363;
    data[20] = 3290;
    data[21] = 2947;
    data[22] = 2327;
    data[23] = 1824;
    data[24] = 1603;
    data[25] = 1314;
    data[26] = 1022;
    data[27] = 513;
    data[28] = 331;
    data[29] = 323;
    data[30] = 297;
    data[31] = 280;
    data[32] = 286;
    data[33] = 263;
    data[34] = 260;
    data[35] = 270;
    data[36] = 257;
    data[37] = 249;
    data[38] = 248;
    data[39] = 260;
    data[40] = 245;
    data[41] = 236;
    data[42] = 240;
    data[43] = 254;
    data[44] = 236;
    data[45] = 238;
    data[46] = 240;
    data[47] = 271;
    data[48] = 313;
    data[49] = 856;
    data[50] = 1331;
    data[51] = 1701;
    data[52] = 2093;
    data[53] = 2403;
    data[54] = 2753;
    data[55] = 3144;
    data[56] = 3296;
    data[57] = 3283;
    data[58] = 3285;
    data[59] = 3298;
    data[60] = 3337;
    data[61] = 3299;
    data[62] = 3338;
    data[63] = 3366;
    data[64] = 3405;
    data[65] = 3371;
    data[66] = 3356;
    data[67] = 3370;
    data[68] = 3378;
    data[69] = 3304;
    
    return data;
  }

  int[] setInputSingleImpulse(int dataLength, int multY, int pulseWidth, int offset, boolean positivePolarity){
    
    if (pulseWidth < 2) {
      pulseWidth = 2;
    }
   
    int center = (dataLength/2) + offset;
    int halfPositives = pulseWidth / 2;
    int startPos = center - halfPositives;
    int stopPos = center + halfPositives;
    
    int[] data = new int[dataLength];
    
    // head
    for (int c = 0; c < dataLength; c++) {
      data[c] = 0;
    }
    
    // pulse
    if (positivePolarity){
      for (int c = startPos; c < stopPos; c++) {
        data[c] = 1 * multY;
      }
    }else{
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
  
  int[] setInputSquareWave(int dataLength, int wavelength, int multY){
    
    double sinPoint = 0;
    double squarePoint = 0;
    int data[] = new int[dataLength];
    
    for(int i = 0; i < data.length; i++)
    {
       sinPoint = Math.sin(2 * Math.PI * i/wavelength);
       squarePoint = Math.signum(sinPoint);
       //println(squarePoint);
       data[i] =(int)(squarePoint) * multY;
    }
    return data;
  }
}