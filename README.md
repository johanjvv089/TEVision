Author:Johan Jansen van Vuuren

Version:1.0

Date:20/08/2017
Revision: 05/10/2017

IMPORTANT:  OpenCV needs to be installed on host system. See http://opencv.org/quickstart.html

Usage:
 
Using The Haskell Tool Stack:
 - Build:  stack build
 - Run  :  stack exec TEVision                      (Process all image files)
 - Run  :  stack exec TEVision imagepath.extension  (Process specified image file)
 
Using binary:
 - Run  :  ./TEVision
 - Run  :  ./TEVision imagepath.extension 
 
Features:
 - Cycles through image files in folder
 - Canny edge detection
 - Apply perspective transform to detected documents
 - Write output to files
 
Notes:
 - image source files should be in the same directory as the executable
 - the output directory is /Output/

TODO:
 - performance tuning
 - concurrency
 - shrink images before processing for speedup
