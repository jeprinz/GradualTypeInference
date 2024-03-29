{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -fno-warn-implicit-prelude #-}
module Paths_type_inference (
    version,
    getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude

#if defined(VERSION_base)

#if MIN_VERSION_base(4,0,0)
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#else
catchIO :: IO a -> (Exception.Exception -> IO a) -> IO a
#endif

#else
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#endif
catchIO = Exception.catch

version :: Version
version = Version [0,1,0,0] []
bindir, libdir, dynlibdir, datadir, libexecdir, sysconfdir :: FilePath

bindir     = "/home/jacob/.cabal/bin"
libdir     = "/home/jacob/.cabal/lib/x86_64-linux-ghc-8.0.2/type-inference-0.1.0.0-74f3K533alvF8RyKSnBn2o"
dynlibdir  = "/home/jacob/.cabal/lib/x86_64-linux-ghc-8.0.2"
datadir    = "/home/jacob/.cabal/share/x86_64-linux-ghc-8.0.2/type-inference-0.1.0.0"
libexecdir = "/home/jacob/.cabal/libexec"
sysconfdir = "/home/jacob/.cabal/etc"

getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath
getBinDir = catchIO (getEnv "type_inference_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "type_inference_libdir") (\_ -> return libdir)
getDynLibDir = catchIO (getEnv "type_inference_dynlibdir") (\_ -> return dynlibdir)
getDataDir = catchIO (getEnv "type_inference_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "type_inference_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "type_inference_sysconfdir") (\_ -> return sysconfdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
