#pragma once

#include "ofMain.h"

#include "ofxXmlSettings.h"
#include "ofxOsc.h"
#include "ofxGui.h"
#include "ofxKinect.h"
#include "ofxOpenCv.h"
#include "ofxCv.h"

class SensedBlob {
public:
    SensedBlob(){
        label = 0;
        center.x = -1.0f;
        center.y = -1.0f;
        box = ofRectangle( 0, 0, 0, 0 );
        found = true;
        update = true;
    }
    
    unsigned int label;
    glm::vec2 center;
    glm::vec2 velocity;
    ofRectangle box;
    bool found;
    bool update;
};

class ofApp : public ofBaseApp{
	public:
		void setup();
		void update();
		void draw();
		void exit();
		
		void keyPressed(int key);
		void keyReleased(int key);
		void mouseMoved(int x, int y);
		void mouseDragged(int x, int y, int button);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void mouseEntered(int x, int y);
		void mouseExited(int x, int y);
		void windowResized(int w, int h);
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);
        
        
        ofxKinect kinect;
        ofxOscSender  sender;

        ofxCvGrayscaleImage grayImage;
        ofxCvGrayscaleImage grayThreshNear;
        ofxCvGrayscaleImage grayThreshFar;
            
        ofxCv::ContourFinder finder;
       
        ofxPanel panel;
            ofParameter<int> near;
            ofParameter<int> far;
            ofParameter<int> minArea;
            ofParameter<int> maxArea;
            ofParameter<float> sensitivity;
            ofParameter<int> tilt;
                void onTilt( int & value ){ kinect.setCameraTiltAngle( value ); }
            ofParameter<int> threshold;    
            ofParameter<int> persistence;    
            ofParameter<int> maxDistance;    
            ofParameter<bool> vMirror;
            ofParameter<bool> hMirror;


        std::vector<SensedBlob> blobs;
};
