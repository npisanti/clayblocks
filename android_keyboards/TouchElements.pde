

/*
  STILL TO IMPLEMENT:
    radioButton array 
    toggle/momentary switches array
      (if x==1 or y==1 they could also serve as simple strips or ribbons) 
    
  remember that oscP5 is a global variable
*/

abstract class ClayblockElement{
  int x;
  int y; 
  int xBoundaryLo;
  int xBoundaryHi;
  int yBoundaryLo;
  int yBoundaryHi;
  int w;
  int h;
  int deadZone = 14;
  int textColorActive = 200;
  int textColor=100;
  float speedMultiplier=1.65;
  
  abstract void update();
  abstract void display(int alpha); 
  abstract void interact(float actionX, float actionY, boolean firstTouch, int touchId);
    
  PVector isTouchedBy(float actionX, float actionY){
    //uses variable deadZone and make clamping of values
    if(actionX>xBoundaryLo && actionX<xBoundaryHi && actionY>=yBoundaryLo && actionY<yBoundaryHi){
      float returnX=actionX;
      float returnY=actionY;
      if(actionX<=x){
        returnX=x;  
      }else if(actionX>=x+w){
        returnX=x+w;
      }
      if(actionY<=y){
        returnY=y;
      }else if(actionY>=y+h){
        returnY=y+h;
      }
      return new PVector(returnX, returnY, 1);  //the third dimension is used as boolean (true)
    }else{
      return new PVector(actionX, actionY, 0);  //the third dimension is used as boolean  (false);
    }
    
  }
  
  
  
}

// XY pad traveling to destination ------------------------------------------------------------------------------------------------------------------------
class ClayblockXYA extends ClayblockElement{
  
  String oscId;
  float startX;
  float startY;
  float destX;
  float destY;
  float speed;
  float cursor;
  float nowX;
  float nowY;
  float outX;
  float outY;
  boolean sending;
  int leftCleaning;
  int rightCleaning;
  int topCleaning;
  int bottomCleaning;
  int cleaningWidth;
  int cleaningHeight;
  //other elements
  int cursorRadius;
  float startSpeed=0.0005;
  float maxSpeed=0.5;
  
  //tail structure
  float [][] tailX;
  float [][] tailY;
  int tailPos;
  int tailLen;
  
  
  ClayblockXYA(int x, int y, int w, int h, int cursorRadius, String oscId){
    this.oscId=oscId;
    super.x=x;
    super.y=y;
    super.w=w;
    super.h=h;
    super.xBoundaryLo=x-deadZone;
    super.xBoundaryHi=x+w+deadZone;
    super.yBoundaryLo=y-deadZone;
    super.yBoundaryHi=y+h+deadZone;
    this.cursorRadius=cursorRadius;
    this.leftCleaning=x-cursorRadius;
    this.rightCleaning=x+w;
    this.bottomCleaning=y+h;
    this.topCleaning=y-cursorRadius;
    this.cleaningWidth=cursorRadius+w;
    this.cleaningHeight=cursorRadius+h;
    this.startX=0;
    this.startY=h;
    this.destX=0;
    this.destY=h;
    this.speed=startSpeed;
    this.cursor=1;
    this.nowX=0;
    this.nowY=h;
    this.outX=0.0;
    this.outY=0.0;
    this.sending=false;
    this.tailPos=0;
    this.tailLen=14;
    this.tailX = new float[2][tailLen];
    this.tailY = new float[2][tailLen];
    for(int i=0; i<tailLen; i++){
      tailX[0][i]=0.0;  
      tailX[1][i]=0.0;  
      tailY[0][i]=0.0;
      tailY[1][i]=0.0;
    }
    
  }
 
  void update(){
    if(cursor!=1){
      cursor+=speed;
      if(cursor>=1){
        nowX=destX;
        nowY=destY;
        cursor=1;
        speed=startSpeed;
      }else{
        nowX=startX+(destX-startX)*cursor;
        nowY=startY+(destY-startY)*cursor; 
      }
      outX=map(nowX, 0, w, 0.0, 1.0);
      outY=map(nowY, 0, h, 1.0, 0.0); //reversed range to have lowest on the bottom
      
      //osc comm
      OscMessage myMessage = new OscMessage(oscId);
      myMessage.add(outX);
      myMessage.add(outY); 
      oscP5.send(myMessage, myRemoteLocation);
      sending=true;
    }else{
      sending=false;
    }

  }
  
  void interact(float actionX, float actionY, boolean firstTouch, int touchId){
    destX = actionX - x;
    destY = actionY - y;
    startX=nowX;
    startY=nowY;
    cursor=0;
    if(firstTouch){
      speed=startSpeed;  
    }else{
      if(speed<maxSpeed){
        speed=speed*speedMultiplier;
      }else{
        speed=maxSpeed;
      }
    }
  }
  
  void display(int alpha){
    
    pushMatrix();
    noFill();
    //plotting border
    stroke(255);
    rectMode(CORNER);
    rect(x,y,w,h);
    
    //plotting data
    if(sending){
      fill(textColorActive);
    }else{
      fill(textColor);
    }
    text(oscId, x+15, y+20);
    text(outX, x+5, y+40);
    text(outY, x+5, y+60);
    noFill();
    //plotting cursors
    translate(x,y);
    stroke(255, alpha*0.6);
    line(destX, 0, destX, h);
    line(0, destY, w, destY);
    //line(destX-cursorRadius, destY, destX+cursorRadius, destY);
    //line(destX, destY-cursorRadius, destX, destY+cursorRadius);
    rectMode(CORNERS);
    stroke(255, alpha);
    
    float x1=nowX-cursorRadius;
    float x2=nowX+cursorRadius;
    float y1=nowY-cursorRadius;
    float y2=nowY+cursorRadius;
    if(x1<0){ x1=0; }
    if(x2>w){ x2=w; }
    if(y1<0){ y1=0; }
    if(y2>h){ y2=h; }
    rect(x1, y1, x2, y2);
    
    for(int i=0; i<tailLen; i++){
      stroke(255, alpha*(tailLen-i)/tailLen);
      int pos2 = (tailPos+i)%tailLen;
      rect(tailX[0][pos2], tailY[0][pos2], tailX[1][pos2], tailY[1][pos2]);
    }
    
    tailPos=(tailPos-1+tailLen)%tailLen;
    tailX[0][tailPos] = x1;
    tailX[1][tailPos] = x2;
    tailY[0][tailPos] = y1;
    tailY[1][tailPos] = y2;   
    
    popMatrix();  
  }
  
  
}


// Ribbon Controller with on/off detection------------------------------------------------------------------------------------------------------------------------
class ClayblockRibbon extends ClayblockElement{
  
  String oscId;
  float destX;
  float easing=0.7;
  float nowX;
  float outX;
  boolean sending;
  boolean touched;
  boolean offMessageNotSent;
  boolean gateReading;
  
  ClayblockRibbon(int x, int y, int w, int h, String oscId){
    this.oscId=oscId;
    super.x=x;
    super.y=y;
    super.w=w;
    super.h=h;
    super.xBoundaryLo=x-deadZone;
    super.xBoundaryHi=x+w+deadZone;
    super.yBoundaryLo=y-deadZone;
    super.yBoundaryHi=y+h+deadZone;
    this.destX=0;
    this.nowX=0;
    this.outX=0.0;    
    this.sending=false;
    this.touched=false;
    this.offMessageNotSent=false;
    this.gateReading=false;
  }
 
  void update(){
    if(nowX!=destX){
      if(abs(destX-nowX)>1.0){
        nowX+= (destX-nowX)*easing;   
      }else{
        nowX=destX; 
      }
      outX=map(nowX, 0, w, 0.0, 1.0);
      
      //osc comm
      OscMessage myMessage = new OscMessage(oscId);
      myMessage.add(outX);
      myMessage.add(1);  //on
      oscP5.send(myMessage, myRemoteLocation);
      offMessageNotSent=true;
      sending=true;
    }else{
      if(touched){
         //osc comm
        OscMessage myMessage = new OscMessage(oscId);
        myMessage.add(outX);
        myMessage.add(1);  //on
        oscP5.send(myMessage, myRemoteLocation);
        sending=true; 
        offMessageNotSent=true;
        touched=false;  //if it's still touched it will be reset to true before the next cycle
      }else{
        sending=false;
        if(offMessageNotSent){
           OscMessage myMessage = new OscMessage(oscId);
           myMessage.add(outX);
           myMessage.add(0);  //off
           oscP5.send(myMessage, myRemoteLocation);
           offMessageNotSent=false;
        }
      }  
    }
  }
  
  void interact(float actionX, float actionY, boolean firstTouch, int touchId){
    destX = actionX-x;
    touched=true;
  }
  
  
  void display(int alpha){
    
    pushMatrix();
    noFill();
    if(sending){
      fill(textColorActive);
    }else{
      fill(textColor);
    }
    text(oscId, x+15, y+20);
    text(outX, x+5, y+40);
    if(gateReading){
      if(sending){
        text("1", x+15, y+60);
      }else{
        text("0", x+15, y+60);
      }
    }
    noFill();
    
    //plotting border
    stroke(255);
    rectMode(CORNER);
    rect(x,y,w,h);
    //plotting cursors
    translate(x,y);
    stroke(255);
    line(nowX, 0, nowX, h);
    stroke(150);
    if(abs(destX-nowX)<deadZone){
      if(!(nowX-deadZone<0)) line(nowX-deadZone, 0, nowX-deadZone, h);
      if(!(nowX+deadZone>w)) line(nowX+deadZone, 0, nowX+deadZone, h);
    }else{   
      line(destX, 0, destX, h);
      line(nowX*2-destX, 0, nowX*2-destX, h);
    }
    stroke(255);
    popMatrix();  
  }
  
  void setGateDisplay(boolean displayGate){
    gateReading=displayGate;
  }
  
}


//Fader--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
class ClayblockFader extends ClayblockElement{
  
  String oscId;
  float destY;
  float easing=0.5;
  float nowY;
  float outY;
  boolean sending;
  boolean touched;
  boolean offMessageNotSent;
  boolean gateReading;
  
  ClayblockFader(int x, int y, int w, int h, String oscId){
    this.oscId=oscId;
    super.x=x;
    super.y=y;
    super.w=w;
    super.h=h;
    super.xBoundaryLo=x-deadZone;
    super.xBoundaryHi=x+w+deadZone;
    super.yBoundaryLo=y-deadZone;
    super.yBoundaryHi=y+h+deadZone;
    this.destY=h;
    this.nowY=h;
    this.outY=0.0;    
    this.sending=false;
    this.touched=false;
    this.offMessageNotSent=false;
    this.gateReading=false;
  }  
 
  void update(){
    
    if(nowY!=destY){
      if(abs(destY-nowY)>1.0){
        nowY+= (destY-nowY)*easing;   
      }else{
        nowY=destY; 
      }
      outY=map(nowY, 0, h, 1.0, 0.0);
      
      //osc comm
      OscMessage myMessage = new OscMessage(oscId);
      myMessage.add(outY);
      myMessage.add(1);  //on
      oscP5.send(myMessage, myRemoteLocation);
      offMessageNotSent=true;
      sending=true;
    }else{
      if(touched){
         //osc comm
        OscMessage myMessage = new OscMessage(oscId);
        myMessage.add(outY);
        myMessage.add(1);  //on
        oscP5.send(myMessage, myRemoteLocation);
        sending=true; 
        offMessageNotSent=true;
        touched=false;  //if it's still touched it will be reset to true before the next cycle
      }else{
        sending=false;
        if(offMessageNotSent){
           OscMessage myMessage = new OscMessage(oscId);
           myMessage.add(outY);
           myMessage.add(0);  //off
           oscP5.send(myMessage, myRemoteLocation);
           offMessageNotSent=false;
        }
      }  
    }
  }
  
  void interact(float actionX, float actionY, boolean firstTouch, int touchId){
    destY = actionY-y;
    touched=true;
  }
  
  
  void display(int alpha){
    
    pushMatrix();
    noFill();
    if(sending){
      fill(textColorActive);
    }else{
      fill(textColor);
    }
    text(oscId, x+15, y+20);
    text(outY, x+5, y+40);
    
    
    if(gateReading){
      if(sending){
        text("1", x+15, y+60);
      }else{
        text("0", x+15, y+60);
      }
    }
    noFill();
    
    //plotting border
    stroke(255);
    rectMode(CORNER);
    rect(x,y,w,h);
    //plotting cursors
    translate(x,y);
    stroke(255);
    line(0, nowY, w, nowY);
    stroke(150);
    if(abs(destY-nowY)<deadZone){
      if(!(nowY-deadZone<0)) line(0 ,nowY-deadZone, w, nowY-deadZone);
      if(!(nowY+deadZone>h)) line(0, nowY+deadZone, w, nowY+deadZone);
    }else{
      line(0, destY, w, destY);
      line(0, nowY*2-destY, w, nowY*2-destY);
    }
    stroke(255);
    popMatrix();  
  }
  
  void setGateDisplay(boolean displayGate){
    gateReading=displayGate;
  }

  
}