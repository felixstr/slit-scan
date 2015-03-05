import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.video.*; 

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
int rowHeight = 50;

HashMap<Integer,PImage> frameBuffer = new HashMap<Integer,PImage>();

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

	image(video, 0, 0);

}	

public void readFrame() {
	frameBuffer.put(frameCount, captureToImage(video));
}

public void drawImage() {
	int top = 0;
	while(top < height) {



		top += rowHeight;
	}
}

public PImage captureToImage(Capture capture) {
	PImage img = createImage(width, height, RGB);
	img.loadPixels();
	img.pixels = capture.pixels;

	img.updatePixels();
	return img;

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
