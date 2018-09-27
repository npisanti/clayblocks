#pragma once

#include "ofMain.h"
#include "ofxCv.h"
#include "ofxCvPiCam.h"
#include "ofxOsc.h"
#include "ofxOscParameterSync.h"

class SensedBlob {
public:
    SensedBlob(){
        label = 0;
        center.x = -1.0f;
        center.y = -1.0f;
        velocity.x = 0.0f;
        velocity.y = 0.0f;
        boundaries = ofRectangle( 0, 0, 0, 0 );
        found = true;
        update = true;
    }
    
    unsigned int label;
    glm::vec2 center;
    glm::vec2 velocity;
    ofRectangle boundaries;
    bool found;
    bool update;
};

class ofApp : public ofBaseApp {
public:
	void setup();
	void update();
	void draw();
    void exit();
    
    void doBlobs();
    
    ofxCvPiCam cam;
    
    cv::Mat red;
    std::vector <cv::Mat> channels;
    
    cv::Mat frame;
    cv::Mat undistorted;
    cv::Mat tLow;
    cv::Mat tHigh;
    cv::Mat thresh;
    
    cv::Mat background;
    
    ofxCv::Calibration calibration;
    ofxCv::ContourFinder finder;
    
    ofParameterGroup settings;
        ofParameterGroup camera;
            ofParameter<int> width;
            ofParameter<int> height;
            ofParameter<std::string> file;
            ofParameter<int> saturation;
            ofParameter<int> sharpness;
            ofParameter<int> contrast;
            ofParameter<int> brightness;
            ofParameter<int> awbMode;
            ofParameter<int> exposureMode;
        ofParameterGroup network;
            ofParameter<std::string> ip;
            ofParameterGroup ports;
            ofParameter<int> trackingPort;
            ofParameter<int> imagePort;
            ofParameter<int> syncSendPort;
            ofParameter<int> syncReceivePort;
        ofParameterGroup parameters;
            ofParameter<bool> doBackgroundSubtraction;
            ofParameter<int> low;
            ofParameter<int> high;
            ofParameter<int> minArea;
            ofParameter<int> maxArea;
            ofParameter<float> distSensitivity;
            ofParameter<float> veloSensitivity;
            ofParameter<int> persistence;    
            ofParameter<int> maxDistance;   
            ofParameter<float> deadzoneWidth; 
            ofParameter<float> deadzoneHeight; 
            ofParameter<int> sendImage;
        ofParameter<bool> drawToScreen;
    
    float minX, maxX, minY, maxY;
    
    bool bTakeBackground;
    
    void onBGSubtractionToggle( bool & value );
    void onDeadzone( float & value );

    std::vector<SensedBlob> blobs;
    float divideW, divideH;
        
    ofxOscParameterSync sync;
    ofxOscSender  sender;
    ofxOscSender  debugger;
    char * buffer;
    size_t buffersize; 
    
    
    
};
