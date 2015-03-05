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
int rowHeight = 10;
float rowDelay = 50;

// HashMap<Integer,PImage> frameBuffer = new HashMap<Integer,PImage>();
ArrayList<PImage> frameBuffer = new ArrayList<PImage>();

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
	drawImage();


	// bufferClean();

	// image(video, 0, 0);
	// if (frameCount > 300) {
	// 	image(frameBuffer.get(200), 0,0);
	// } else {
	// 	image(video, 0, 0);
	// }
	// image(video, 0, 0);
}	

public void readFrame() {
	frameBuffer.add(video.get());
}
int i = 0;
public void drawImage() {
	int top = 0;
	float frameDelayStep = (rowDelay/1000* frameRate);
	println(frameDelayStep);
	
	if (frameBuffer.size() > frameDelayStep*2) {
		// image(frameBuffer.get(frameBuffer.size()-60), 0,0);
		// image(frameBuffer.get(20), 0,0);
	



	// Entry<Integer, PImage> lastEntry = frameBuffer.lastEntry();
	// println(lastEntry);
	// image(frameBuffer.get(lastEntry), 0,0);

	// // println(frameCount);
	// int currentFrame = frameNumber;
	// int newFrame = 0;

	// if (currentFrame > 400) {
	// 	newFrame = currentFrame-500;
	// 	if (current) {
	// 		image(frameBuffer.get(currentFrame), 0,0);
	// 	} else {

	// 		image(frameBuffer.get(newFrame), 0,0);
	// 	}

	// 	println("frameCount: "+frameNumber+", frameCount100: "+(newFrame));

	// 	i++;
	// }

		int step = 0;
		int frameDelay = 0;
		while (top < height-rowHeight) {
			frameDelay = PApplet.parseInt(frameBuffer.size() - (frameDelayStep * step) - 1);
			// println("frameDelay: "+frameDelay);
			if (frameDelay > 0) {
				PImage frameImage = frameBuffer.get(frameDelay).get(0, top, width, rowHeight);

				image(frameImage, 0, top);
			}

			step++;
			top += rowHeight;
		}

	}
}

public void bufferClean() {


}

boolean current = true;
public void keyPressed() {
	switch (key) {
		case ' ':
			current = !current;
		break;
	}
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
