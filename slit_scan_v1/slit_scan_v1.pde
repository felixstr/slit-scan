import processing.video.*;
import java.util.*;

Capture video;
int rowHeight = 10;
float rowDelay = 50;
boolean topToBottom = true;

int frameNumber = 0;

ArrayList<PImage> frameBuffer = new ArrayList<PImage>();
// HashMap<Integer, PImage> frameBuffer = new HashMap<Integer, PImage>();

void setup() {
	size(640, 480);

	video = new Capture(this, width, height, 30);
	video.start();
}

void draw() {
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

void readFrame() {
	frameBuffer.add(video.get());
	// frameBuffer.put(frameNumber, video.get());
}

void drawImage() {
	int top = 0;
	float frameDelayStep = (rowDelay/1000* frameRate);
	
	

		int step = 0;
		int frameDelay = 0;

		while (top < height-rowHeight) {
			frameDelay = int(frameBuffer.size() - (frameDelayStep * step) - 1);
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

void bufferClean() {
	// anzahlrows * delay
	// for (int i = 0; i < frameBuffer.size(); i++) {
	// 	if ()
	// }
	// println(height/rowHeight);
	// println(frameBuffer.size());

}
