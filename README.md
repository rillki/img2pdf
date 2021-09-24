# img2pdf
Image to PDF conversion utility written in D programming language. [Download](https://github.com/rillki/img2pdf/releases) the precompiled binary or build it yourself down below.

<img src="assets/screenshot.jpeg">

### Usage
```
=========================================================
img2pdf  v1.3 -- Image to PDF converter.
---------------------------------------------------------
USAGE:
	img2pdf [path] [images] [file] {options}

OPTIONS:
	[stretch]   stretch img to PDF page size
		    -strue, -sfalse
	[order]     sort files (ascending, descending)
		    -asc, -desc

DEFAULTS:
	[path]     cwd/ ('/' or '\\' path identifier)
	[images]   all *.jpg, *.png in [path]
	[file]     [path]/output.pdf
	[stretch]  -strue
	[order]    -asc

EXAMPLE:
	img2pdf ../temp/ img1.png,img2.jpg myImages.pdf
		-sfalse -asc
=========================================================
```

### Building and Installing
#### Required
* [D compiler](https://dlang.org/download) (DMD is recommended)
* [DUB](https://dub.pm) package manager

##### Note for Windows 10 users
When downloading DMD, choose `exe`. It is the official D `installer` that will install both `DMD` and `DUB` to your system. 

#### Dependencies (managed by DUB automatically)
* [printed](https://github.com/AuburnSounds/printed)

#### Compiling
1. Clone the repository to your machine:
```
git clone https://github.com/rillki/img2pdf.git
```
2. Open your terminal or command line and go to `img2pdf` folder:
```
cd img2pdf
```
3. Build the binary
```
dub --build=release
```

Your will find the binary in the `bin/` folder. Add it to your `PATH` to use it freely. 

Here is an article on how to add an executable binary to `PATH` on [Windows 10](https://medium.com/@kevinmarkvi/how-to-add-executables-to-your-path-in-windows-5ffa4ce61a53).

### LICENSE
All code is licensed under [MIT](https://github.com/rillki/img2pdf/blob/main/LICENSE) license.












