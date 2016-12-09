class KernelGenerator {
  // by Douglas Mayhew 12/1/2016
  // This class creates a kernel and saves it's data into an array

// a menu of various one dimensional kernels, example: kernel = setArray(gaussian); 
float [] gaussian = {0.0048150257, 0.028716037, 0.10281857, 0.22102419, 0.28525233, 0.22102419, 0.10281857, 0.028716037, 0.0048150257};
// float [] sorbel = {1, 0, -1};
// float [] gaussianLaplacian = {-7.474675E-4, -0.0123763615, -0.04307856, 0.09653235, 0.31830987, 0.09653235, -0.04307856, -0.0123763615, -7.474675E-4};
// float [] laplacian = {1, -2, 1}; 

  KernelGenerator (int kernelsource) {
    switch (kernelsource) {
    case 0:
      // a dynamically created gaussian bell curve kernel
      kernel = makeGaussKernel1d(gaussianKernelSigma); 
      break;
    case 1:
      // a hard-coded gaussian kernel
      kernel = setArray(gaussian);
      break;
    default:
      // a hard-coded gaussian kernel, hard to mess up.
      kernel = setArray(gaussian);
  }
  
  KERNEL_LENGTH = kernel.length; 
  println("KERNEL_LENGTH: " + KERNEL_LENGTH);
  HALF_KERNEL_LENGTH = KERNEL_LENGTH / 2;
  
  // some other kernels we experimented with, but don't need here because our preferred subpixel edge detection method is decided.
  
  // A hard-coded Sorbel kernel
  // kernel = setArray(sorbel);
  
  // Laplacians are used to find edges using the 2nd derivative method, by looking for zero-crossings after running it.
  // but our preferred method of fitting a parabola to the peaks of the 1st derivative is more accurate, it being a sub-pixel method.
  
  // A hard-coded Laplacian kernel
  // kernel = setArray(laplacian);
  
  // A hard-coded Gaussian-Laplacian kernel (combination of Gaussian and Laplacian, the 'Mexican Hat Filter')
  // This kernel saves a convolution step by combining two kernels which would otherwise be run seperately, into one.
  // kernel = setArray(gaussianLaplacian);

  // A dynamically created Gaussian Laplacian kernel (combination of Gaussian and Laplacian, the 'Mexican Hat Filter')
  // This kernel saves a convolution step by combining two kernels which would otherwise be run seperately, into one.
  // kernel = createLoGKernal1d(loGKernelSigma); 
  
  }
  
  float [] setArray(float [] inArray) {
  
  float[] kernel = new float[inArray.length]; // set to an odd value for an even integer phase offset
  kernel = inArray;
  
  for (int i = 0; i < kernel.length; i++) {
    println("setArray kernel[" + i + "] = " + kernel[i]);
  }
    
  return kernel;
  }
  
  float [] makeGaussKernel1d(double sigma) {
    
   /**
   * This sample code is made available as part of the book "Digital Image
   * Processing - An Algorithmic Introduction using Java" by Wilhelm Burger
   * and Mark J. Burge, Copyright (C) 2005-2008 Springer-Verlag Berlin, 
   * Heidelberg, New York.
   * Note that this code comes with absolutely no warranty of any kind.
   * See http://www.imagingbook.com for details and licensing conditions.
   * 
   * Date: 2007/11/10
   
   code found also at:
   https://github.com/biometrics/imagingbook/blob/master/src/gauss/GaussKernel1d.java
   */
  
    // scaling variables
    double sum = 0;
    double scale = 1;
    
    // create the kernel
    int center = (int) (3.0 * sigma);
    // using a double internally for greater precision
    // set to an odd value for an even integer phase offset
    double[] kernel = new double [2*center+1]; 
    // using a float for the final return value
    float[] fkernel = new float [2*center+1];
    
    // fill the kernel
    double sigmaSquared = sigma * sigma;
    for (int i=0; i<kernel.length; i++) {
      double r = center - i;
      kernel[i] = (double) Math.exp(-0.5 * (r*r)/ sigmaSquared);
      sum += kernel[i];
      //println("gaussian kernel[" + i + "] = " + kernel[i]);
    }
    
    if (sum!=0.0){
      scale = 1.0/sum;
    } else {
      scale = 1;
    }
    
    //println("gaussian kernel scale = " + scale); // print the scale.
    sum = 0; // clear the previous sum
    // scale the kernel values
    for (int i=0; i<kernel.length; i++){
      kernel[i] = kernel[i] * scale;
      fkernel[i] = (float) kernel[i];
      sum += kernel[i];
      // print the kernel value.
     // println("scaled gaussian kernel[" + i + "]:" + fkernel[i]); 
    }
    
    if (sum!=0.0){
      scale = 1.0/sum;
    } else {
      scale = 1;
    }
    
    // print the new scale. Should be very close to 1.
    //println("gaussian kernel new scale = " + scale); 
    return fkernel;
  }
  
  float[] createLoGKernal1d(double deviation) {
    
    int center = (int) (4 * deviation);
    int kSize = 2*center+1; // set to an odd value for an even integer phase offset
    // using a double internally for greater precision
    double[] kernel = new double[kSize];
    // using a float for the final return value
    float[] fkernel = new float [kSize];  // float version for return value
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
       // println("LoG kernel[" + x + "] = " + fkernel[x]);
    }
    return fkernel;
  }
}