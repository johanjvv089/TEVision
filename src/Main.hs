module Main where

import qualified Data.ByteString as B 
import qualified Data.Vector as V
--import Control.Concurrent
import Control.Monad (void,when)
import Data.List   
import GHC.Word  
import OpenCV
import System.Directory
import System.Environment
import System.Exit

import Filters
import Transforms
import Utilities

main :: IO ()
main = do
      --Read images------------------------------------------------------------------------------------
        args <- getArgs
        if (length args > 0) 
           then do
               let fname = args !! 0 --file specified
               process [fname]
           else do                   --no file specified,do all
                filePaths <- listDirectory "../data/"
                let imgPaths = sort $ filter isImgFile filePaths --sort and filter - only image files  
                createDirectoryIfMissing True "../data/Output"
                putStrLn $ "Image Files: \n"++show imgPaths++"\n"
                if length imgPaths == 0
                    then exitWith ExitSuccess --no images found
                    else process imgPaths --process images

        
process::[FilePath]->IO ()
process files = do   
        img <- imdecode ImreadGrayscale <$> B.readFile ("../data/"++ (head files))
        let formimg = exceptError $ coerceMat img :: Mat (S [ D, D]) (S 1) (S Word8)
        sharpImg <- (enhanceEdges $ gaussianBlurImg formimg 7) >>= (morphImg MorphOpen 1) >>= (morphImg MorphClose 1) -- blur and sharpen formatted image
        thickEdges <- morphImg MorphGradient 2 $ cannyImg sharpImg -- do gradient detection (2 iterations)    
        
        --detect contours
        contours <- getContours thickEdges --get contours
        rawConts <- rawContours contours -- contours with children removed - flattened contour hierarchy  
        appConts <- approximateContours contours -- polygonal approximation of contours
        let quadrilaterals = V.filter isSimplePolygon $ V.filter isLong $ V.filter isQuad appConts -- large enough contours with four vertices - candidates for documents
             
        --putStrLn $ "Number of documents detected in image:"  ++head files++":  " ++ (show $ V.length quadrilaterals)
        
--         imgM     <- thaw img
--         drawContours (rawConts) red   (OutlineContour LineType_8 5) imgM --action to mutate imgMut  
--         imgCont  <-freeze imgM
--         showImage "Raw Contours" imgCont
--        
--         imgMut   <- thaw img  
--         drawContours (quadrilaterals) red   (OutlineContour LineType_8 5) imgMut --action to mutate imgMut  
--         imgContA <-freeze imgMut
--         showImage "Approximated contours" imgContA 
        
        if          (V.length quadrilaterals <= 0 && length files > 1) -- process next image if no outlines and there are more images waiting 
            then    process (tail files)
        else if     (V.length quadrilaterals >  0 && length files > 1) -- save objects and process next image if outlines and there are more images waiting 
            then do
                    saveDetectedObjects (1) quadrilaterals img $ head files
                    process (tail files)
        else if     (V.length quadrilaterals > 0)                                                               
            then do
                    saveDetectedObjects (1) quadrilaterals img $ head files
                    putStrLn "\nDONE!"
                    exitWith ExitSuccess                                      -- no more images remaining    
        else        exitWith ExitSuccess                                      --terminate if this was the last image
        
        --showImage "Canny before closing" edgeImg
        --showImage "Erode" $ erodeImg 5 sharpImg
        --showImage "Dilate canny" $ closingImg $ cannyImg $ gaussianBlurImg (medianBlurImg (closingImg $ openingImg sharpImg) 3) 7
        --showImage "Orig" img
        --showImage "Sharpen after blur: Sharp <- gauss <- form <- orig" sharpImg
        --showImage "Sharpen no blur: Sharp <- gauss <- form <- orig" sharpImg'
        --showImage "Opening <- sharp <- gauss <- form <- orig" $ openingImg sharpImg
        --showImage "Closing <- opening <- sharp <- gauss <- form <- orig" $ closingImg $ openingImg sharpImg
        --showImage "Gauss <- closing <- opening <- sharp <- gauss <- form <- orig"  $ gaussianBlurImg (closingImg $ openingImg sharpImg) 9
        --showImage "Canny with preblur<- Gauss <- closing <- opening <- sharp <- gauss <- form <- orig" edgeImg
        --showImage "Canny no preblur<- Gauss <- closing <- opening <- sharp <- gauss <- form <- orig" edgeImg'

showImage::String-> Mat (S [height, width]) channels depth-> IO ()
showImage title img = withWindow title $ \window -> do  --display image
                        imshow window img
                        resizeWindow window 1200 700 
                        void $ waitKey 100000
                        
saveDetectedObjects::Int->(V.Vector (V.Vector Point2i))-> Mat (S [ D, D]) (D) (D)->String->IO ()
saveDetectedObjects iter contours img fname
    | (V.null contours)   == True = putStrLn "NO OBJECTS DETECTED!"
    | otherwise                   = do
        let correctedImg = correctImg (orderPts $ contours V.! 0) img
        --showImage "Corrected: " correctedImg
        B.writeFile ("../data/Output/"++fnameNoExt++"_"++show iter++".tif") $ exceptError $ imencode OutputTiff correctedImg
        putStrLn $ "Wrote to file: ../data/Output/"++fnameNoExt++"_"++show iter++".tif" 
        when (V.length contours > 1) $ saveDetectedObjects (iter+1) (V.tail contours) img fname
    where fnameNoExt = reverse $ drop 4 $ reverse fname