module app;

// phobos
import std.stdio: writefln;
import std.array: array, empty;
import std.file: write, exists, getcwd, dirEntries, SpanMode;
import std.path: dirSeparator, buildPath, baseName;
import std.conv: to;
import std.algorithm: splitter, filter, map, canFind, sort, reverse;
import std.getopt: getopt, GetoptResult, defaultGetoptPrinter;

// printed
import printed.canvas: PDFDocument, IRenderingContext2D, Image;

// pdf document dimensions
immutable pageWidthmm = 210.0;
immutable pageHeightmm = 297.0;

void main(string[] args) {
	if(args.length < 2) {
		writefln("\n#img2pdf: no commands provided! See \'img2pdf -h\' for more info.\n");
		return;
	}

	// command line boolean arguments
	bool bversion = false;
	bool bstretch = true;
	bool bsortAscending = true;
	bool borientLandscape = false;

	// command line arguments
	string 
		path = getcwd(), 
		images = null, 
		outputFile = "output.pdf";
	string[] imageList = null;

	// parsing arguments
	GetoptResult argInfo;
	try {
		argInfo = getopt(
			args,
			"version|v", "command utility version", &bversion,
			"stretch|s", "stretch img to PDF page size", &bstretch,
			"ascending|a", "sort asceding", &bsortAscending,
			"landscape|l", "landscape PDF page orientation", &borientLandscape,
			"path|p", "path to images directory", &path,
			"images|i", "specify image names seperated by \',\'", &images, 
			"output|o", "output PDF file name", &outputFile
		);

		// print help if needed
		if(argInfo.helpWanted) {
			defaultGetoptPrinter("\nimg2pdf version v1.6 -- Image to PDF converter.", argInfo.options);
			writefln("\nEXAMPLE: img2pdf --path=../temp --images=img1.png,img2.jpg --output=myImages.pdf\n");
			return;
		}

		// print version
		if(bversion) {
			writefln("img2pdf version 1.6 -- Image to PDF converter.");
			return;
		}

		// split images
		imageList = (images is null) ? path.listdir.filter!(
				a => a.canFind(".jpg", ".jpeg", ".png")
			).array.sort!("a < b").map!(
				a => path.buildPath(a)
			).array : images.splitter(',').map!(a => path.buildPath(a)).array;

		// if no images are found, exit
		if(imageList.empty) {
			writefln("\n#img2pdf: no images found!\n");
			return;
		}

		// start
		writefln("\n#img2pdf: starting conversion...\n");

		// convert images
		img2pdf(
			outputFile,
			(bsortAscending ? imageList : imageList.dup.reverse),
			bstretch,
			!borientLandscape
		);

		// end
		writefln("\n#img2pdf: finished...\n");
	} catch(Exception e) {
		writefln("\n#img2pdf: error! %s\n", e.msg);
		return;
	}
}

/++
List all files found in a directory

Params:
	dir = directory to inspect

Returns: an array of file names
+/
string[] listdir(const string dir) {
    return dirEntries(dir, SpanMode.shallow)
        .filter!(a => a.isFile)
        .map!(a => baseName(a.name))
        .array;
}

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
	int nfdontExist = 0;	// for tracking when a new page should be added
	foreach(i, img; images) {
		// checks if image exists
		if(!img.exists) {
			nfdontExist++;

			writefln("#img2pdf: (%s) <%s> does not exist! Skipping...", i, img);
			continue;
		} else {
			// create a new page
			if(i > 0 + nfdontExist) {
				context.newPage();
			}
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
	writefln("#img2pdf: saving <%s> to cwd.", pdfDocumentName);
	try {
		pdfDocumentName.write(pdf.bytes);
	} catch(Exception e) {
		writefln("#img2pdf: failed to save <%s>; %s", pdfDocumentName, e.msg);
	}
}
