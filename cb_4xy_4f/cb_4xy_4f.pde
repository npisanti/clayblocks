import oscP5.*;
import netP5.*;
import android.view.MotionEvent;
import java.util.*;  
  
PFont font;
OscP5 oscP5;
NetAddress myRemoteLocation;
ClayblockElement[] elements;

int numElements=8;
int horizBorder = 20;
int vertBorder = 20;
int rowSpace = 36;
int cRadius = 16;
int faderWidth=60;

int faderHeight= (800 - rowSpace*3 - horizBorder*2 )/4;
int xyWidth = 1280 - (vertBorder*2) - faderWidth - rowSpace;

void setup() {
  orientation(LANDSCAPE);
  rectMode(CENTER);
  noFill();
  stroke(255);
  //set up font
  font = loadFont(  "DialogInput.plain-16.vlw");
  textFont(font, 16);
  
  /* start listening on port 12001, incoming messages must be sent to port 12001 */
  oscP5 = new OscP5(this, 12001);

  //remember to set the right IP address, check with ifconfig command   
  myRemoteLocation = new NetAddress("10.42.0.1", 12000);
  
  
  //CONTROLS------------------------------------------------------------------------------------------------------------------------------------------------

  elements = new ClayblockElement[numElements];
  
  int plotX=0;
  int plotY=horizBorder;
   
  int i =0;
  int xyToken=0;
  int fToken=0;
  
  //voices= new ClayblockVoicePool(8, 20);
  
  for(int yy=0; yy<4; yy++){
       plotX=vertBorder;
       
       elements[i]=new ClayblockFader(plotX, plotY, faderWidth, faderHeight, "/f"+(fToken++));
       i++;
       plotX+=faderWidth+rowSpace;
       
       elements[i]=new ClayblockXYA(plotX, plotY, xyWidth, faderHeight, cRadius, "/xy"+(xyToken++));
       i++;
       
       plotY+=faderHeight+rowSpace;       
  }
  
  //END CONTROL CREATION---------------------------------------------------------------------------------------------------------------------------------
}

void draw() {
  background(0);  
  noSmooth();
  
  
  //voices.reset();
  
  //MULTI TOUCH CONTROL
  synchronized(multiTouch) {      
    Iterator it = multiTouch.entrySet().iterator();

    while (it.hasNext ()) {
      Map.Entry pairs = (Map.Entry)it.next();
      Touch t = (Touch) pairs.getValue();
      Integer id = (Integer) pairs.getKey();

      //code using touch here
      if (t.touched)
      { 
         for(int i=0; i<numElements; i++){
           PVector query = elements[i].isTouchedBy(t.motionX, t.motionY);
           
           if(query.z==1){
             elements[i].interact(query.x, query.y, !t.ptouched, id);             
           }
         }        
      } // end of code using touch
      
    } // while (it.hasNext () )
  } // synchronized(touch)
  
  
  //voices.update();
  
  //updating and displaying controls
  for(int i=0; i<numElements; i++){
      elements[i].update();
      elements[i].display(255);     
  }   
   
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage message) {}