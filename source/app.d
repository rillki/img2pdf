module app;

// phobos
import std.stdio: writefln;
import std.array: array, empty;
import std.file: write, exists, getcwd, dirEntries, SpanMode;
import std.path: dirSeparator, buildPath, baseName;
import std.conv: to;
import std.algorithm: splitter, filter, map, canFind, sort, reverse;

// printed
import printed.canvas: PDFDocument, IRenderingContext2D, Image;

// pdf document dimensions
immutable pageWidthmm = 210.0;
immutable pageHeightmm = 297.0;

void main(string[] args) {
	if(args.length < 2) {
		("\n=========================================================\n" ~
			"img2pdf  v1.5 -- Image to PDF converter.\n" ~
			"---------------------------------------------------------\n" ~
			"USAGE:\n\timg2pdf [path] [images] [file] {options}\n" ~
			"\nOPTIONS:\n" ~
			"\t{version}   returns the latest version\n" ~
			"\t\t    -v, -version\n" ~
			"\t{stretch}   stretch img to PDF page size\n" ~
			"\t\t    -strue, -sfalse\n" ~
			"\t{order}     sort files (ascending, descending)\n" ~
			"\t\t    -asc, -desc\n" ~
			"\t{orient}    orientation (portrait, landscape)\n" ~
			"\t\t    -portrait, -landscape\n" ~
			"\nDEFAULTS:" ~
			"\n\t[path]     cwd/ (\'/\' or \'\\\\\' path identifier)" ~
			"\n\t[images]   all *.jpg, *.png in [path]" ~
			"\n\t[file]     [path]/output.pdf" ~
			"\n\t{stretch}  -strue" ~
			"\n\t{order}    -asc" ~
			"\n\t{orient}   -portrait\n" ~
			"\nEXAMPLE:\n\timg2pdf ../temp/ img1.png,img2.jpg myImages.pdf\n" ~
			"\t\t-sfalse -asc -portrait\n" ~
			"=========================================================\n"
		).writefln;
		return;
	}

	// version
	if(args.length == 2 && args[1].canFind("-v", "-version")) {
		writefln("img2pdf version 1.5 -- Image to PDF converter.");
		return;
	}

	// remove binary name
	args = args[1..$];

	auto findArg = (const string sfind, const string sdefault){
		auto temp = args.filter!(a => a.canFind(sfind)).array;
		return (
			temp.empty ?
			sdefault :
			temp[0]
		);
	};

	// find path
	immutable path = findArg(dirSeparator, getcwd);
	if(!path.exists) {
		writefln("\n#img2pdf: directory <%s> is does not exist!\n", path);
		return;
	}

	// find pdf document name, stretch image to pdf, file sorting order, orientation
	immutable pdfDocumentName = path.buildPath(findArg(".pdf", "output.pdf"));
	immutable stretchToPDFSize = findArg("-sfalse", null).empty;
	immutable sortAscending = findArg("-desc", null).empty;
	immutable orientPortrait = findArg("-landscape", null).empty;

	// find images
	auto arg_images = args.filter!(a => a.canFind(".jpg", ".jpeg", ".png")).array;
	immutable images = (
		arg_images.empty ?
		path.listdir.filter!(a => a.canFind(".jpg", ".jpeg", ".png")).array.sort!("a < b").map!(a => path.buildPath(a)).array :
		arg_images[0].splitter(',').map!(a => path.buildPath(a)).array
	).to!(immutable string[]);


	// if no images are found, exit
	if(images.empty) {
		writefln("\n#img2pdf: no images found!\n");
		return;
	}

	// start
	writefln("\n#img2pdf: starting conversion...\n");

	// convert images
	img2pdf(
		pdfDocumentName,
		(sortAscending ? images : images.dup.to!(string[]).reverse),
		stretchToPDFSize,
		orientPortrait
	);

	// end
	writefln("\n#img2pdf: finished...\n");
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
