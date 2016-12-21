class MovingAverageFilter { 
  private int kernelSize = 0; // length of kernel window
  private float[] kernelData;   // array to hold kernel window values
  private double total = 0.0;      // holds sum of kernel values
  private float avg = 0.0;        // holds average of kernel values
  private float pAvg = 0.0;       // holds previous average of kernel values
  private int p = 0;          // pointer for kernel array traversal
  private int n = 0;          // counter for kernel array traversal

  MovingAverageFilter (int kSize) { 
    kernelSize = kSize;
    kernelData = new float[kernelSize];
    reset();
  }

  // Use the next value and calculate the
  // moving average
  void nextValue(float value) { 
    total -= kernelData[p];
    kernelData[p] = value;
    total += value;
    p = ++p % kernelSize;
    if (n < kernelSize) n++;
    pAvg = avg;
    avg = (float) (total / n);
  }

  // Read property average
  public float getAverage() {
    return avg;
  }

  // Read property, previous average
  public float getPAverage() {
    return pAvg;
  }

  public void reset() {
    total = 0;
    avg = 0;
    pAvg = 0;
    p = 0;
    n = 0;
    for (int v = 0; v < kernelSize; v++) {
      kernelData[v]=0;
    }
  }
}