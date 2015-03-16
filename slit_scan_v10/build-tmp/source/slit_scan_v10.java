import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.video.*; 
import java.util.*; 
import SimpleOpenNI.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class slit_scan_v10 extends PApplet {





Capture video;

public void setup() {
	video = new Capture(this, 960, 540, "HD Pro Webcam C920", 15);
	video.start();

	size(960, 540, P2D);

	
}

public boolean sketchFullScreen() { return false; }

int rowSize = 10;
int yPos = height-rowSize;

public void draw() {
	frame.setLocation(0,0);
	frameRate(120);

	if (video.available()) {
		video.read();
	}
	
	video.loadPixels();

	// image(video.get(), 0, 0);

	image(video.get(0, yPos, width, rowSize), 0 ,yPos);
	yPos -= rowSize; 
	if (yPos < 0) {
		yPos = height-rowSize;
	}

	// println(yPos);
}	
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "slit_scan_v10" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
