import processing.video.*;
import java.util.*;

Capture video;
int rowHeight = 50;
int rowDelay = 1;

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


	// bufferClean();

	// image(video, 0, 0);
	// if (frameCount > 300) {
	// 	image(frameBuffer.get(200), 0,0);
	// } else {
	// 	image(video, 0, 0);
	// }
	// image(video, 0, 0);
}	

void readFrame() {
	frameBuffer.add(video.get());
}
int i = 0;
void drawImage() {
	int top = 0;
	int frameDelayStep = int(rowDelay * 60);
	println(frameDelayStep);
	
	if (frameBuffer.size() > frameDelayStep+1) {
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
		while (top < height) {
			frameDelay = (frameDelayStep * step) - 1;
			image(frameBuffer.get(frameBuffer.size()-1), 0, top);

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
