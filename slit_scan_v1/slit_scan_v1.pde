import processing.video.*;
import java.util.*;

Capture video;
int rowHeight = 10;
float rowDelay = 50;

// HashMap<Integer,PImage> frameBuffer = new HashMap<Integer,PImage>();
ArrayList<PImage> frameBuffer = new ArrayList<PImage>();

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
	drawImage();

}	

void readFrame() {
	frameBuffer.add(video.get());
}
int i = 0;
void drawImage() {
	int top = 0;
	float frameDelayStep = (rowDelay/1000* frameRate);
	println(frameDelayStep);
	
	if (frameBuffer.size() > frameDelayStep*2) {
	

		int step = 0;
		int frameDelay = 0;
		while (top < height-rowHeight) {
			frameDelay = int(frameBuffer.size() - (frameDelayStep * step) - 1);
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

void bufferClean() {


}

boolean current = true;
void keyPressed() {
	switch (key) {
		case ' ':
			current = !current;
		break;
	}
}
