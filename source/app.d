module app;

import std;

void main(string[] args) {
	if(args.length < 2) {
		("\n========================================================\n" ~
			"img2pdf  v1.0 -- Image to PDF converter.\n" ~
			"--------------------------------------------------------\n" ~
			"USAGE:\n\timg2pdf [path] [imgs] [file] [verbose]\n" ~
			"DEFAULTS:\n\t[path]\t  cwd/ (\'/\' path identifier)\n\t[imgs]\t  all *.jpg, *.png in path\n\t[file]\t  path/output.pdf\n\t[verbose] -v or --verbose (false)\n" ~
			"EXAMPLE:\n\timg2pdf ../temp/ img1.png,img2.jpg myImages.pdf\n" ~
			"========================================================\n"
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

	// verbose output
	immutable verbose = !args.filter!(a => a.canFind("verbose")).array.empty;

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
		path.listdir.filter!(a => a.canFind(".jpg", ".jpeg", ".png")).array.sort!("a < b").array :
		arg_images[0].splitter(',').array
	).to!(immutable string[]);

	// if no images are found, exit
	if(images.empty) {
		writefln("\n#img2pdf: images not found!\n");
		return;
	}

	// convert images
	writefln("\n#img2pdf: starting conversion...\n");
	if(verbose) {
		// print all images that don't exist
		images.filter!(a => !path.buildPath(a).exists).array.each!(a => writefln("#img2pdf: <%s> does not exist!", a));
	}
	img2pdf(pdfName, images.map!(a => path.buildPath(a)).array, verbose);
	writefln("\n#img2pdf: finished...\n");
}

void img2pdf(const string pdfName, const string[] imgs, const bool verbose) {
	import std.file: write;
	import printed.canvas: PDFDocument, IRenderingContext2D, Image;
	
	auto pdf = new PDFDocument();
	auto context = cast(IRenderingContext2D)(pdf);
	
	// print images to pdf
	foreach(img; imgs) {
		// checks if image exists
		if(!img.exists) { continue; }

		// open image
		auto currentImg = new Image(img);
		
		// print image to pdf
		context.drawImage(currentImg, 0, 0, context.pageWidth, context.pageHeight);
		
		// create new page
		context.newPage();
	}
	
	pdfName.write(pdf.bytes);
}

string[] listdir(string dir) {
    return dirEntries(dir, SpanMode.shallow)
        .filter!(a => a.isFile)
        .map!(a => baseName(a.name))
        .array;
}
