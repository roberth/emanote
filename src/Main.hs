{-# LANGUAGE TypeApplications #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Main where

import Control.Lens.Operators ((.~))
import Control.Monad.Logger (MonadLogger)
import Data.Default (Default (def))
import Data.LVar (LVar)
import Ema (Ema)
import qualified Ema
import qualified Ema.Helper.FileSystem as FileSystem
import qualified Ema.Helper.Tailwind as Tailwind
import Emanote.Model (Model)
import qualified Emanote.Model as M
import Emanote.Route (MarkdownRoute)
import qualified Emanote.Route as R
import qualified Emanote.Source as Source
import qualified Emanote.Template as Template
import Main.Utf8 (withUtf8)
import UnliftIO (MonadUnliftIO)

topLevelStaticPaths :: [FilePath]
topLevelStaticPaths = ["favicon.jpeg", "favicon.svg", "static"]

instance Ema Model MarkdownRoute where
  encodeRoute = R.encodeRoute
  decodeRoute = R.decodeRouteExcept $ one . fromString <$> topLevelStaticPaths
  staticRoutes = M.staticRoutes
  staticAssets _ = topLevelStaticPaths

main :: IO ()
main =
  withUtf8 $
    Ema.runEma (\a -> Template.render $ cssShim a) run
  where
    cssShim =
      Tailwind.twindShim

run :: (MonadUnliftIO m, MonadLogger m) => LVar Model -> m ()
run model = do
  defaultTmpl <- Source.defaultTemplateState
  defaultData <- Source.defaultData
  let model0 =
        def
          & M.modelHeistTemplate .~ defaultTmpl
          & M.modelDataDefault .~ defaultData
  -- TODO: Monitor defaultTmpl directory; only if running in ghcid.
  -- Otherwise configure ghcid to reload when this directory is changed.
  FileSystem.mountOnLVar "." Source.filePatterns model model0 $ \sources action -> do
    Source.transformActions sources action