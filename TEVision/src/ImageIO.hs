module ImageIO(
    showImage
   ,showDetectedObjects
   ,showObjectsWithCorners
)   where
    
import qualified OpenCV as CV
import qualified OpenCV.Internal.Core.Types.Mat as M
import qualified OpenCV.Internal.Core.Types.Point as P
import qualified OpenCV.ImgProc.StructuralAnalysis as SA 
import qualified Data.Vector as V
import Control.Monad (void)
import GHC.Int (Int32)
import Linear.V2

import Transforms
import Utilities

showImage::String-> M.Mat (CV.S '[height, width]) channels depth-> IO ()
showImage title img = CV.withWindow title $ \window -> do  --display image
                        CV.imshow window img
                        CV.resizeWindow window 500 500
                        void $ CV.waitKey 100000
                        
showDetectedObjects::Int->(V.Vector SA.Contour)->M.Mat (CV.S '[height, width]) channels depth->IO ()
showDetectedObjects iter contours imgOrig
    | (V.null contours)   == True = error "NO OBJECTS DETECTED!"
    | (V.length contours) == 1    = showImage ("Object "++(show iter)) (cropImg imgOrig (CV.fromPoint (CV.rectTopLeft uprightBounder)::(V2 Int32)) (CV.fromSize  (CV.rectSize uprightBounder)::(V2 Int32)))
    | otherwise                   = do
                                    showImage ("Object "++(show iter)) (cropImg imgOrig (CV.fromPoint (CV.rectTopLeft uprightBounder)::(V2 Int32)) (CV.fromSize  (CV.rectSize uprightBounder)::(V2 Int32)))
                                    showDetectedObjects (iter+1) (V.tail contours) imgOrig
    where uprightBounder = getUprightBoundRect contours
          
showObjectsWithCorners::Int->(V.Vector SA.Contour)->M.Mat (CV.S '[height, width]) channels depth->IO ()
showObjectsWithCorners iter contours imgOrig
    | (V.null contours)   == True = error "NO OBJECTS DETECTED!"
    | (V.length contours) == 1    = do
        let points = (SA.contourPoints (contours V.! 0))
        let rotRect = findEnclosingRectangle points
        let a  = getRectCorners rotRect
        let p1 = getPt 1 a    
        let p2 = getPt 2 a
        let p3 = getPt 3 a
        let p4 = getPt 4 a
        mutImg <-CV.thaw imgOrig
        CV.circle mutImg (P.toPoint p1) 4 blue (-1) CV.LineType_AA 0
        CV.circle mutImg (P.toPoint p2) 4 blue (-1) CV.LineType_AA 0
        CV.circle mutImg (P.toPoint p3) 4 blue (-1) CV.LineType_AA 0
        CV.circle mutImg (P.toPoint p4) 4 blue (-1) CV.LineType_AA 0
        circled_img <- CV.freeze mutImg
        showImage ("Corners of object "++show iter) circled_img
    | otherwise                   = do
        let points = (SA.contourPoints (contours V.! 0))
        let rotRect = findEnclosingRectangle points
        let a  = getRectCorners rotRect
        let p1 = getPt 1 a    
        let p2 = getPt 2 a
        let p3 = getPt 3 a
        let p4 = getPt 4 a
        mutImg <-CV.thaw imgOrig
        --TODO make circle sizes proportional to image size
        CV.circle mutImg (P.toPoint p1) 4 blue (-1) CV.LineType_AA 0
        CV.circle mutImg (P.toPoint p2) 4 blue (-1) CV.LineType_AA 0
        CV.circle mutImg (P.toPoint p3) 4 blue (-1) CV.LineType_AA 0
        CV.circle mutImg (P.toPoint p4) 4 blue (-1) CV.LineType_AA 0
        circled_img <- CV.freeze mutImg
        showObjectsWithCorners (iter+1) (V.tail contours) circled_img
