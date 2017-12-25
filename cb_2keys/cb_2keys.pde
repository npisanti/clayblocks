import oscP5.*;
import netP5.*;
import android.view.MotionEvent;
import java.util.*;  
  
PFont font;
OscP5 oscP5;
NetAddress myRemoteLocation;
ClayblockVoicePool voices;
ClayblockElement[] elements;
int numElements=2;

int horizBorder = 20;
int vertBorder = 20;//(1280- xySide*4 -offset*3)/2;
int rowSpace = 40;

int cRadius = 16;
int xySide = 280;
int faderWidth=72;
int ribbonSpacing = 30;

int offset = (1280-xySide*4-vertBorder*2)/3;
int faderHeight= (800 - rowSpace - horizBorder*2 )/2;

int ribbonHeight = faderHeight -ribbonSpacing -xySide;


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
  
  int plotX=vertBorder;
  int plotY=horizBorder;
  int secondRow = horizBorder+faderHeight+offset; 
  
  voices= new ClayblockVoicePool(8, 24);
  
  elements[0] = new ClayblockGraviKeys(20,  horizBorder, 1240, faderHeight, 65, 13, voices);
  elements[1] = new ClayblockGraviKeys(20, horizBorder+faderHeight+rowSpace, 1240, faderHeight, 53, 13, voices);
  
  //END CONTROL CREATION---------------------------------------------------------------------------------------------------------------------------------
}

void draw() {
  background(0);  
  noSmooth();
  
  
  voices.reset();
  
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
  
  
  voices.update();
  
  //updating and displaying controls
  for(int i=0; i<numElements; i++){
      elements[i].update();
      elements[i].display(255);     
  }   
   
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  
}