module pdfed;

// phobos
import std.stdio: writefln;
import std.array: array;
import std.file: write, exists;
import std.path: dirSeparator;
import std.algorithm: splitter, filter, map;

// printed
import printed.canvas: PDFDocument, IRenderingContext2D, Image;

// pdf document dimensions
immutable pageWidthmm = 210.0;
immutable pageHeightmm = 297.0;

/++
Converts images to a PDF file

Params:
	pdfDocumentName = pdf file name
	images = an array image names including the path
	stretchToPDFSize = stretches image to pdf page width and height, `true` by default 
	orientPortrait = portrait page orientation, `true` by default
+/
void img2pdf(const string pdfDocumentName, const string[] images, const bool stretchToPDFSize = true, const bool orientPortrait = true) {	
	// create a pdf document
	PDFDocument pdf;
	if(orientPortrait) {
		pdf = new PDFDocument(pageWidthmm, pageHeightmm);
	} else {
		pdf = new PDFDocument(pageHeightmm, pageWidthmm);
	}
	auto context = cast(IRenderingContext2D)(pdf);
	
	// prints images to pdf
	foreach(i, img; images) {
		// creates a new page
		if(i > 0) {
			context.newPage();
		}

		// checks if image exists
		if(!img.exists) { 
			writefln("#img2pdf: (%s) <%s> does not exist! Skipping...", i, img);
			continue; 
		}

		// opens an image (skips the image upon failure)
		Image currentImg;
		try {
			currentImg = new Image(img);
		} catch(Exception e) {
			writefln("#img2pdf: (%s) <%s> failed to open; %s", i, img, e.msg);
			continue;
		}
		
		// prints an image to a blank pdf page
		if(stretchToPDFSize) {
			context.drawImage(currentImg, 0, 0, context.pageWidth, context.pageHeight);
		} else {
			context.drawImage(currentImg, 0, 0);
		}
		
		writefln("#img2pdf: (%s) <%s> converted!", i, img.splitter(dirSeparator).array[$-1]);
	}
	
	// writes data to pdf file
	writefln("#img2pdf: saving <%s>", pdfDocumentName);
	try {
		pdfDocumentName.write(pdf.bytes);
	} catch(Exception e) {
		writefln("#img2pdf: failed to save <%s>; %s", pdfDocumentName, e.msg);		
	}
}










