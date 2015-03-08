import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.video.*; 
import java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class slit_scan_v1 extends PApplet {




Capture video;
int rowHeight = 1;
float rowDelay = 10;
boolean topToBottom = true;

int frameNumber = 0;

ArrayList<PImage> frameBuffer = new ArrayList<PImage>();
// HashMap<Integer, PImage> frameBuffer = new HashMap<Integer, PImage>();

public void setup() {
	size(640, 480);

	video = new Capture(this, width, height, 30);
	video.start();
}

public void draw() {
	background(0);

	// println(frameCount);

	if (video.available()) {
		video.read();
	}
	

	video.loadPixels();
	readFrame();

	pushMatrix();
		scale(-1, 1);
		translate(-width, 0);
		drawImage();	

	popMatrix();

	bufferClean();
}	

public void readFrame() {
	frameBuffer.add(video.get());
	// frameBuffer.put(frameNumber, video.get());
}

public void drawImage() {
	int top = 0;
	float frameDelayStep = (rowDelay/1000* frameRate);
	
	

		int step = 0;
		int frameDelay = 0;

		while (top < height-rowHeight) {
			frameDelay = PApplet.parseInt(frameBuffer.size() - (frameDelayStep * step) - 1);
			// println("frameDelay: "+frameDelay);
			if (frameDelay > 0) {
				int imageTop = top;
				if (!topToBottom) {
					imageTop = height-top-rowHeight;
				}

				PImage frameImage = frameBuffer.get(frameDelay).get(0, imageTop, width, rowHeight);

				image(frameImage, 0, imageTop);
			}

			step++;
			top += rowHeight;
		}

		// println("frameBuffer Size: "+frameBuffer.size()+" frameDelay: "+frameDelay);


}

public void bufferClean() {
	// anzahlrows * delay
	// for (int i = 0; i < frameBuffer.size(); i++) {
	// 	if ()
	// }
	// println(height/rowHeight);
	// println(frameBuffer.size());

}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "slit_scan_v1" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
