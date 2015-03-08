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

public class slit_scan_v2 extends PApplet {





SimpleOpenNI context;

Capture video;
int rowHeight = 10;
float rowDelay = 80;

float frameDelayStep = 1;

boolean topToBottom = false;

int frameNumber = 0;

HashMap<Integer, PImage> frameBuffer = new HashMap<Integer, PImage>();

public void setup() {
	size(640*3/2, 480*3/2);
	
	video = new Capture(this, 640, 480, 30);
	video.start();
	
	// frameDelayStep = (rowDelay/1000)* frameRate;
	println("frameDelayStep: "+frameDelayStep);
}

public void draw() {
	background(0);
	// image(context.rgbImage(), 0, 0);

	// println(frameCount);

	if (video.available()) {
		video.read();
	}
	
	video.loadPixels();
	
	readFrame();

	pushMatrix();
		scale(-1.66f, 1.66f);
		translate(-640, 0);
		drawImage();	

	popMatrix();

	frameNumber++;
	
}	

public void readFrame() {
	frameBuffer.put(frameNumber, video.get());
}

public void drawImage() {

	// image(frameBuffer.get(frameNumber), 0, 0);
	
	
	int top = 0;
	int step = 0;
	int frameDelay = 0;

	while (top < height) {
		frameDelay = PApplet.parseInt(frameNumber - (frameDelayStep * step));
		
		// println("frameDelay: "+frameDelay);
		if (frameDelay > 0 && frameBuffer.get(frameDelay) != null) {
			int imageTop = top;
			if (!topToBottom) {
				imageTop = height-top-rowHeight;
			}

			PImage frameImage = frameBuffer.get(frameDelay).get(0, imageTop, width, rowHeight);

			image(frameImage, 0, imageTop);
		}



		
		top += rowHeight;
		step++;
	}

	bufferClean(frameDelay);
	


	// println("frameBuffer Size: "+frameBuffer.size());


}

public void bufferClean(int frameDelay) {
	// anzahlrows * delay
	if (frameBuffer.get(frameDelay-1) != null) {
		ArrayList<Integer> deleteElements = new ArrayList<Integer>();


		Iterator itr = frameBuffer.entrySet().iterator();
		while(itr.hasNext()) {
			Map.Entry mapEntry = (Map.Entry)itr.next();
			int bufferFrameNumber = (Integer)mapEntry.getKey();

			if (bufferFrameNumber < frameDelay-50) {
				deleteElements.add(bufferFrameNumber);
				
			}

		}

		for (int i = 0; i < deleteElements.size(); i++) {
			frameBuffer.remove(deleteElements.get(i));
			// println("deleted: "+deleteElements.get(i));
		}
	}

}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "slit_scan_v2" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
