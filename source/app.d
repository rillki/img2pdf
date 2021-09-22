module app;

import std;

void main(string[] args) {
	if(args.length < 2) {
		("\n=========================================================\n" ~
			"img2pdf  v1.1 -- Image to PDF converter.\n" ~
			"---------------------------------------------------------\n" ~
			"USAGE:\n\timg2pdf [path] [imgs] [file] [stretch]\n" ~
			"DEFAULTS:\n\t[path]\t  cwd/ (\'/\' path identifier)" ~ 
			"\n\t[imgs]\t  all *.jpg, *.png in path\n\t[file]\t  path/output.pdf" ~
			"\n\t[stretch] -strue (stretch img to PDF page size)\n" ~
			"EXAMPLE:\n\timg2pdf ../temp/ img1.png,img2.jpg myImages.pdf\n" ~
			"\t\t-sfalse\n" ~
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
	immutable path = findArg("/", getcwd);
	if(!path.exists) {
		writefln("\n#img2pdf: directory <%s> is does not exist!\n", path);
		return;
	}
	
	// find pdfName
	immutable pdfName = path.buildPath(findArg(".pdf", "output.pdf"));

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

	// find if stretch argument is false
	immutable stretch = findArg("sfalse", null).empty;

	// start
	writefln("\n#img2pdf: starting conversion...\n");
	
	// convert images
	img2pdf(pdfName, images, stretch);
	
	// end
	writefln("\n#img2pdf: finished...\n");
}

/+
Converts images to a PDF file

Params:
	pdfName = pdf file name
	imgs = an array image names including the path
	stretchToPDFSize = stretches image to pdf page width and height, `true` by default 
+/
void img2pdf(const string pdfName, const string[] imgs, const bool stretchToPDFSize = true) {
	import std.file: write;
	import printed.canvas: PDFDocument, IRenderingContext2D, Image;
	
	auto pdf = new PDFDocument();
	auto context = cast(IRenderingContext2D)(pdf);
	
	// print images to pdf
	foreach(i, img; imgs) {
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
		
		// creates a new page
		context.newPage();
	}
	
	// writes data to pdf file
	writefln("#img2pdf: saving <%s>", pdfName);
	pdfName.write(pdf.bytes);
}

/+
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


















