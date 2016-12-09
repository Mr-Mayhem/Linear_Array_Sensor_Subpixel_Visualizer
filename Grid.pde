class Grid {
  // This class draws a grid
  
  Grid () {
 
  }
  
  void drawGrid(int gWidth, int gHeight, int divisor)
  {
    int widthSpace = gWidth/divisor;   // Number of Vertical Lines
    int heightSpace = gHeight/divisor; // Number of Horozontal Lines
    
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