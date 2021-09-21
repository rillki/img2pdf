module app;

import std.file: write;	

import printed.canvas;

void main(string[] args) {
	"assets/output2.pdf".toPDF(["assets/cat.jpg"]);
}

void toPDF(const string filename, const string[] imgs) {
	import std.file: write;
	import printed.canvas: PDFDocument, IRenderingContext2D;
	
	auto pdf = new PDFDocument();
	auto context = cast(IRenderingContext2D)(pdf);
	
	// print images to pdf
	foreach(img; imgs) {
		// open image
		auto currentImg = new Image(img);
		
		// print image to pdf
		context.drawImage(currentImg, 0, 0, context.pageWidth, context.pageHeight);
		
		// create new page
		context.newPage();
	}
	
	filename.write(pdf.bytes);
}
