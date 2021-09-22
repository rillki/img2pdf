module app;

import std;

void main(string[] args) {
	if(args.length < 2) {
		("\n========================================================\n" ~
			"img2pdf  v1.0 -- Image to PDF converter.\n" ~
			"--------------------------------------------------------\n" ~
			"USAGE:\n\timg2pdf [path] [imgs,coma,seperated] [file.pdf]\n" ~
			"DEFAULTS:\n\tpath\tcwd\n\timgs\tall files in path\n\tfile\tpath/output.pdf\n" ~
			"EXAMPLE:\n\timg2pdf ../temp/ img1.png,img2.jpg myImages.pdf\n" ~
			"========================================================\n"
		).writeln;
		return;
	}
	
	// find path,pdfname,imgs
}

void toPDF(const string pdfName, const string[] imgs) {
	import std.file: write;
	import printed.canvas: PDFDocument, IRenderingContext2D, Image;
	
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
	
	pdfName.write(pdf.bytes);
}
