#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
        
    blobs.reserve(64); // more than enough
    blobs.clear();
        
    // ---------------------    
    ofSetVerticalSync(true);
    ofSetFrameRate(120);

    // LOADING XML SETTINGS
    ofxXmlSettings netSettings;
    std::cout <<  "[xml settings] loading \n";
    if( netSettings.loadFile( ofToDataPath("network.xml") ) ){
        std::cout << "[xml netSettings] network.xml loaded!\n";
    }else{
        std::cout << "[xml netSettings] error! unable to load network.xml\n";
        ofExit();
    }
    std::string ip = netSettings.getValue("network:client_ip", "localhost");
    int port = netSettings.getValue("network:port", 12345);   
    std::cout << "[xml netSettings] sending to "<<ip<<" | port="<<port<<"\n";
    
    panel.setup("settings", "settings.xml", 640*2 + 20, 20 );
    panel.add(far.set("far threshold", 120, 0, 255) );
    panel.add(near.set("near threshold", 255, 0, 255) );
    panel.add(minArea.set("area min", 20, 1, 640*480) );
    panel.add(maxArea.set("area max", 50000, 1, 100000) );
    panel.add(sensitivity.set("update sensitivity", 10.0f, 1.0f, 80.0f) );
    panel.add(tilt.set("tilt", 0, -30, 30) );
    tilt.addListener( this, &ofApp::onTilt );
    panel.add( threshold.set("cv threshold", 50, 1, 100) );
    panel.add( persistence.set("cv persistence", 15, 1, 100) );
    panel.add( maxDistance.set("cv max distance", 32, 1, 100) );
    panel.add( vMirror.set("vertical mirror", false ) );
    panel.add( hMirror.set("horizontal mirror", false ) );
    panel.loadFromFile("settings.xml");
    
    // setup OSC
    sender.setup( ip, port );

    // setup kinect with color image disabled
    kinect.init(false, false); 
    kinect.open();	
    kinect.setCameraTiltAngle( tilt );
    
    grayImage.allocate(kinect.width, kinect.height);
    grayThreshNear.allocate(kinect.width, kinect.height);
    grayThreshFar.allocate(kinect.width, kinect.height);

    ofBackground( 30, 0, 0 );
}

//--------------------------------------------------------------
void ofApp::update(){
    kinect.update();
    
    if(kinect.isFrameNew()) {
        
        grayImage.setFromPixels(kinect.getDepthPixels().getData(), kinect.width, kinect.height);
        if( hMirror || vMirror ) grayImage.mirror( hMirror, vMirror );
        
        grayThreshNear = grayImage;
        grayThreshFar = grayImage;
        grayThreshNear.threshold( near, true);
        grayThreshFar.threshold( far );
        cvAnd(grayThreshNear.getCvImage(), grayThreshFar.getCvImage(), grayImage.getCvImage(), NULL);
        grayImage.flagImageChanged();
        
        // set contour tracker parameters
        finder.setMinArea(minArea);
        finder.setMaxArea(maxArea);
        finder.setThreshold(threshold);
        finder.setFindHoles( false ); 
        
        finder.getTracker().setPersistence(persistence);
        finder.getTracker().setMaximumDistance(maxDistance);
        
        // determine found contours
        finder.findContours(grayImage);
                    
        
        for ( auto & blob : blobs ){ blob.found = false; }
        
        for( size_t i=0; i<finder.size(); ++i ){
            
            bool insert = true;
            
            for( auto & blob : blobs ){
                
                if( finder.getLabel(i) == blob.label ){
                    blob.found = true;
                    insert = false;
                    
                    if( glm::distance( blob.center, glm::vec2(finder.getCenter(i).x, finder.getCenter(i).y) ) > sensitivity ){
                        blob.center.x = finder.getCenter(i).x;
                        blob.center.y = finder.getCenter(i).y;
                        blob.box = ofxCv::toOf( finder.getBoundingRect(i) );
                        blob.update = true;
                    }
                    break;
                }
            }
            
            if( insert ){
                blobs.emplace_back();
                blobs.back().center.x = finder.getCenter(i).x;
                blobs.back().center.y = finder.getCenter(i).y;
                blobs.back().box = ofxCv::toOf( finder.getBoundingRect(i) );
                blobs.back().label = finder.getLabel(i);
            }
            
        }
        
        // now delete all the not found and send OSC message for that
        auto it = blobs.begin();
        for ( ; it != blobs.end(); ) {
            if( ! it->found ){
                ofxOscMessage m;
                m.setAddress( "kinect/blobs/delete" );
                m.addIntArg( it->label );
                sender.sendMessage(m, false);
                it = blobs.erase( it );
            }else{
                it++;
            } 
        }
        
        // send all the messages for the blobs to update 
        for( auto & blob : blobs ){
            if( blob.update ){
                ofxOscMessage m;
                m.setAddress( "kinect/blobs/update" );
                
                m.addIntArg( blob.label );
                // normalized coords
                m.addFloatArg( blob.center.x / 640.0f );
                m.addFloatArg( blob.center.y / 480.0f );
                // normalized bounding box
                m.addFloatArg( blob.box.x / 640.0f );
                m.addFloatArg( blob.box.y / 480.0f );
                m.addFloatArg( blob.box.width / 640.0f );
                m.addFloatArg( blob.box.height / 480.0f ); 

                sender.sendMessage(m, false);
                
                blob.update = false;
            }
        }
    }
    
}

//--------------------------------------------------------------
void ofApp::draw(){
#ifndef __ARM_ARCH
        ofSetColor(255);
        kinect.drawDepth( 0, 0, 640, 480 );   
                
        panel.draw();
        
        ofTranslate(640, 0);
        grayImage.draw( 0, 0);
        ofSetColor(255, 0, 0 ); 
        finder.draw();
#endif
}

//--------------------------------------------------------------
void ofApp::exit(){
    kinect.close();
    kinect.setCameraTiltAngle(0);
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){

}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}
