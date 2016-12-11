class Grid {
  // This class draws a grid
  
  Grid () {
 
  }
  
  void drawGrid(float gWidth, float gHeight, float divisor, int panX)
  {
    float widthSpace = gWidth/divisor;   // Number of Vertical Lines
    float heightSpace = gHeight/divisor; // Number of Horozontal Lines
    
    strokeWeight(1);
    stroke(25,25,25); // White Color
    
    // Draw vertical
    for(int i=0; i<gWidth; i+=widthSpace){
      line(i,0,i,gHeight);
     }
     // Draw Horizontal
     for(int w=0; w<gHeight; w+=heightSpace){
       line(0,w,gWidth,w);
     }
  }
}

void drawGrid2(float startX, float stopX, float startY, float stopY, float spacingX, float spacingY) {
  
  strokeWeight(1);
  stroke(25,25,25); // White Color
  for (float x = startX; x <= stopX; x += spacingX) {
    line(x, startY, x, stopY);
  }
  for (float y = startY; y <= stopY; y += spacingY) {
    line(startX, y, stopX, y);
  }
}