import processing.video.*;

Capture video;
int rowHeight = 50;

HashMap<Integer,PImage> frameBuffer = new HashMap<Integer,PImage>();

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

	image(video, 0, 0);

}	

void readFrame() {
	frameBuffer.put(frameCount, captureToImage(video));
}

void drawImage() {
	int top = 0;
	while(top < height) {



		top += rowHeight;
	}
}

PImage captureToImage(Capture capture) {
	PImage img = createImage(width, height, RGB);
	img.loadPixels();
	img.pixels = capture.pixels;

	img.updatePixels();
	return img;

}
