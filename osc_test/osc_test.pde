
// ----------- SETUP ----------------------------
String destinationIP = "192.168.1.4";
int    port          = 4444;
String id            = "zero";
//-----------------------------------------------

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

void setup() {
    frameRate(60);
    oscP5 = new OscP5(this, 42);
    myRemoteLocation = new NetAddress( destinationIP, port);
}

void draw() {
    if ( mousePressed ) {
        background(200);
    } else {
        background(0);
    }
}

void mousePressed() {
    OscMessage myMessage = new OscMessage("/"+ id + "/test");
    myMessage.add( frameCount );
    oscP5.send(myMessage, myRemoteLocation);
}