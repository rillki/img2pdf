module app;

import std;

void main(string[] args) {
	if(args.length < 2) {
		("\n=========================================================\n" ~
			"img2pdf  v1.3 -- Image to PDF converter.\n" ~
			"---------------------------------------------------------\n" ~
			"USAGE:\n\timg2pdf [path] [images] [file] {options}\n" ~
			"\nOPTIONS:\n" ~ 
			"\t[stretch]   stretch img to PDF page size\n" ~
			"\t\t    -strue, -sfalse\n" ~
			"\t[order]     sort files (ascending, descending)\n" ~
			"\t\t    -asc, -desc\n" ~
			"\nDEFAULTS:" ~ 
			"\n\t[path]     cwd/ (\'/\' or \'\\\\\' path identifier)" ~
			"\n\t[images]   all *.jpg, *.png in [path]" ~
			"\n\t[file]     [path]/output.pdf" ~
			"\n\t[stretch]  -strue" ~
			"\n\t[order]    -asc\n" ~
			"\nEXAMPLE:\n\timg2pdf ../temp/ img1.png,img2.jpg myImages.pdf\n" ~
			"\t\t-sfalse -asc\n" ~
			"=========================================================\n"
		).writeln;
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
	
	// find pdf document name, stretch image to pdf, file sorting order
	immutable pdfDocumentName = path.buildPath(findArg(".pdf", "output.pdf"));
	immutable stretchToPDFSize = findArg("-sfalse", null).empty;
	immutable sortAscending = findArg("-desc", null).empty;

	// find images
	auto arg_images = args.filter!(a => a.canFind(".jpg", ".jpeg", ".png")).array;
	immutable images = (
		arg_images.empty ? 
		path.listdir.filter!(a => a.canFind(".jpg", ".jpeg", ".png")).array.sort!("a < b").map!(a => path.buildPath(a)).array :
		arg_images[0].splitter(',').map!(a => path.buildPath(a)).array // add splitter.array if failes to compile
	).to!(immutable string[]);
	

	// if no images are found, exit
	if(images.empty) {
		writefln("\n#img2pdf: no images found!\n");
		return;
	}

	// start
	writefln("\n#img2pdf: starting conversion...\n");
	
	// convert images
	img2pdf(pdfDocumentName, (sortAscending ? images : images.dup.to!(string[]).reverse), stretchToPDFSize);
	
	// end
	writefln("\n#img2pdf: finished...\n");
}

/++
Converts images to a PDF file

Params:
	pdfDocumentName = pdf file name
	images = an array image names including the path
	stretchToPDFSize = stretches image to pdf page width and height, `true` by default 
+/
void img2pdf(const string pdfDocumentName, const string[] images, const bool stretchToPDFSize = true) {
	import std.file: write;
	import printed.canvas: PDFDocument, IRenderingContext2D, Image;
	
	auto pdf = new PDFDocument();
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

		// opens an image
		auto currentImg = new Image(img);
		
		// prints an image to a blank pdf page
		if(stretchToPDFSize) {
			context.drawImage(currentImg, 0, 0, context.pageWidth, context.pageHeight);
		} else {
			context.drawImage(currentImg, 0, 0);
		}
		
		writefln("#img2pdf: (%s) <%s> converted!", i, img.splitter(pathSeparator).array[$-1]);
	}
	
	// writes data to pdf file
	writefln("#img2pdf: saving <%s>", pdfDocumentName);
	pdfDocumentName.write(pdf.bytes);
}

/++
List all files found in a directory

Params:
	dir = directory to inspect

Returns: an array of file names
+/
string[] listdir(string dir) {
    return dirEntries(dir, SpanMode.shallow)
        .filter!(a => a.isFile)
        .map!(a => baseName(a.name))
        .array;
}


















