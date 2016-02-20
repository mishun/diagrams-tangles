{-# LANGUAGE TypeFamilies #-}
module Math.Topology.KnotTh.ChordDiagram.Draw
    ( DrawCDSettings(..)
    , drawCDInsideCircle
    , drawCDInsideCircleDef
    ) where

import Control.Monad.Writer (execWriter, tell)
import Control.Monad (when, forM_)
import Diagrams.Prelude
import Math.Topology.KnotTh.ChordDiagram


data DrawCDSettings =
    DrawCDSettings
        { threadWidth      :: Double
        , threadColour     :: Colour Double
        , borderWidth      :: Double
        , borderColour     :: Colour Double
        , borderDashing    :: [Double]
        , backgroundColour :: Colour Double
        , endpointsRadius  :: Double
        }


defaultDraw :: DrawCDSettings
defaultDraw =
    DrawCDSettings
        { threadWidth      = 0.03
        , threadColour     = black
        , borderWidth      = 0.02
        , borderColour     = black
        , borderDashing    = [0.08, 0.08]
        , backgroundColour = white
        , endpointsRadius  = 0.04
        }


drawCDInsideCircle :: (ChordDiagram cd, N b ~ Double, V b ~ V2, Renderable (Path V2 Double) b) => DrawCDSettings -> cd -> Diagram b
drawCDInsideCircle s cd =
    let p = numberOfChordEnds cd
        polar r a = (r * cos a, r * sin a)
        angle i = 2 * pi * fromIntegral i / fromIntegral p

    in execWriter $ do
        when (endpointsRadius s > 0.0) $
            tell $ fc (threadColour s) $ lwL 0 $ mconcat $
                map (\ i -> translate (r2 $ polar 1 $ angle i) $ circle (endpointsRadius s)) [0 .. p - 1]

        when (borderWidth s > 0.0) $
            tell $ dashingL (borderDashing s) 0 $ lwL (borderWidth s) $ lc (borderColour s) $ circle 1

        let putArc a b =
                let g = 0.5 * (b - a)
                in translate (r2 $ polar (1 / cos g) (0.5 * (a + b))) $
                    scale (tan g) $
                        arc (rotate (b + pi / 2 @@ rad) xDir)
                            (a - b + pi @@ rad)

        tell $ lwL (threadWidth s) $ lc (threadColour s) $ execWriter $
            forM_ [0 .. p - 1] $ \ !i ->
                let j = chordMate cd i
                in if | i > j                -> return ()
                      | isDiameterChord cd i -> tell $ fromVertices $ map (p2 . polar 1 . angle) [i, j]
                      | j - i >= p `div` 2   -> tell $ putArc (angle j) (angle i + 2 * pi)
                      | otherwise            -> tell $ putArc (angle i) (angle j)


drawCDInsideCircleDef :: (ChordDiagram cd, N b ~ Double, V b ~ V2, Renderable (Path V2 Double) b) => cd -> Diagram b
drawCDInsideCircleDef = drawCDInsideCircle defaultDraw
