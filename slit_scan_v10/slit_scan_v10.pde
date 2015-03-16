import processing.video.*;
import java.util.*;
import SimpleOpenNI.*;

Capture video;

void setup() {
	video = new Capture(this, 640, 480, 30);
	video.start();

	size(640, 480, P2D);

	
}

boolean sketchFullScreen() { return false; }

int rowSize = 10;
int yPos = height-rowSize;

void draw() {
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
